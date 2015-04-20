# -*- coding: utf-8 -*-
import sys
import os
import re
import httplib
import urllib2
import time
import json
import string
from urlparse import urlparse
from HTMLParser import HTMLParser
from difflib import SequenceMatcher
# from Foundation import NSLog

import musicbrainzngs
import soundcloud
from mutagen.mp3 import MP3
from mutagen.id3 import ID3, TPE1, TIT1, TIT2, COMM, USLT, APIC, TDRC, TRCK, TALB, TCOM

query = sys.argv[1].strip().replace('–', '-').decode('utf-8')
min_kbps = int(sys.argv[2])
path = sys.argv[3]
access_token = sys.argv[4]
user_id = sys.argv[5]
look_for_matches = "1" in sys.argv[6]
apply_tags = "1" in sys.argv[7]
# NSLog(u"Query: {0}".format(query))
# NSLog("Minimum bitrate: {0}".format(min_kbps))
# NSLog("Saving directory: {0}".format(path))
# NSLog("Access token: {0}".format(access_token))
# NSLog("User id: {0}".format(user_id))
# NSLog("Looking for matches: {0}".format(look_for_matches))
# NSLog("Applying tags: {0}".format(apply_tags))

def main():
    """Reads the given query, looks for matches and downloads the track to the given path if found in VK database.
    """
    global original_query
    original_query = fix_track_name(None, None, query)
    global is_remix
    is_remix = (any(x in original_query.lower() for x in ("remix", "mix", "edit", "mash", "bootleg")) and
                not any(x in original_query.lower() for x in ("(original", "(extended", "(radio", "(dub")))
    global query_comps
    query_comps = [comp.strip() for comp in original_query.split(' - ')]
    global clear_comps
    if len(query_comps) > 1:
        # Clean up the query.
        clear_comps = [clear_artist(query_comps[0]).lower(), clear_title(query_comps[1]).lower()]
    else:
        clear_comps = clear_title(original_query)
    global clear_query
    clear_query = " ".join(clear_comps)
    global match
    match = None
    if look_for_matches: match = get_match()
    if match and len(query_comps) > 1: # If found a match, change the query
        clear_query = u"{0} {1}".format(clear_artist(match.artist), clear_title(match.title)).lower()
    output("Fetching results")
    url = ("https://api.vk.com/method/audio.search?uids=" + str(user_id) + "&q=" +
           urllib2.quote(clear_query.encode('utf-8')) + "&access_token=" + access_token)
    download(sort_results(prepare_results(open_url(url).read())))


def get_match():
    """Looks for matches in MusicBrainz and Soundcloud databases.
    If found any, compares them by similarity to the query and duration.
    Returns the best match.
    """
    output("Looking for a match")
    global track_feat # Featuring artist - for later
    track_feat = None
    matches = []
    # Search for matches on MusicBrainz
    matches.extend(search_mb())
    matches = filter_by_cover(sort_matches(matches))
    track_feat = get_feat(matches)
    if not matches or not matches[0].cover:
        # Search for matches on Soundcloud
        matches.extend(search_soundcloud())
        matches = filter_by_cover(sort_matches(matches))
        if track_feat == None: track_feat = get_feat(matches)
    # Find the longest match if not looking for a radio edit
    if "radio" not in clear_query:
        matches.sort(key=lambda x: x.duration, reverse=True)
    if matches:
        if "feat." in query_comps[0] and track_feat == None:
            track_feat = query_comps[0][string.find(query_comps[0], "feat."):]
        if "feat." not in matches[0].artist and track_feat != None:
            if track_feat.replace("feat. ", "").strip() not in matches[0].artist:
                matches[0].artist += " {0}".format(track_feat)
        # if ("(original mix)" not in matches[0].title.lower() and ("original" in clear_query or not is_remix) and
        # (not matches[0].year or matches[0].year > 2007):
        #    matches[0].title += " (Original Mix)"
        # NSLog(u"Match from {0}: {1} - {2} ({3})".format(matches[0].source, matches[0].artist,
        # matches[0].title, fix_duration(matches[0].duration)))
        print "Found a match"
        return matches[0]
    else:
        output("No match found")
        return None


def sort_matches(matches):
    # Clean up
    for match in matches:
        match.title = fix_track_name(None, match.title)
        match.artist = fix_track_name(match.artist)
    # Sort by similarity to the query
    for match in matches:
        if len(query_comps) > 1:
            search_artist = clear_comps[0]
            search_title = clear_comps[1]
            if search_artist in match.artist:
                artist_ratio = 1.0
            else:
                artist_ratio = SequenceMatcher(None, clear_artist(match.artist).lower(), search_artist).ratio()
            title_ratio = SequenceMatcher(None, clear_title(match.title).lower(), search_title).ratio()
            match.ratio = round((artist_ratio + title_ratio) * 50, 1)
        else:
            artist_ratio = round(SequenceMatcher(None, clear_artist(match.artist).lower(), clear_artist(clear_query)).ratio() * 100, 1)
            title_ratio = round(SequenceMatcher(None, clear_title(match.title).lower(), clear_query).ratio() * 100, 1)
            joined_ratio = round(SequenceMatcher(None, clear_artist(match.artist).lower() + " " +
            clear_title(match.title.lower()), clear_query).ratio() * 100, 1)
            if artist_ratio > title_ratio:
                if artist_ratio > joined_ratio:
                    match.ratio = artist_ratio
                else:
                    match.ratio = joined_ratio
            elif title_ratio > joined_ratio:
                match.ratio = title_ratio
            else:
                match.ratio = joined_ratio
    matches.sort(key=lambda x: x.ratio, reverse=True)
    # Remove unrelated matches
    to_remove = []
    for i in range(len(matches)):
        if matches[i].ratio < 92:
            to_remove.append(i)
    to_remove = sorted(to_remove, reverse=True)
    for junk in to_remove:
        matches.pop(junk)
    return matches

def filter_by_cover(matches):
    with_cover = []
    for match in matches:
        if match.cover and match.duration:
            with_cover.append(match)
    if with_cover:
        return with_cover
    else:
        return matches

def download(results):
    """Downloads the first good result from VK and updates the file's tags.
    """
    if results:
        # Create directory to save to if it doesn't already exist
        if not os.path.exists(path): os.makedirs(path)
        track_info = results[0]
        if match:
            artist = match.artist
            title = match.title
        else:
            # If not match was found, use the result's information for file name and tags
            name = [comp.strip() for comp in fix_track_name(track_info['artist'], track_info['title']).split(' - ')]
            artist = name[0]
            title = name[1]
            if "(original mix)" not in title.lower():
                if not any(x in title.lower() for x in ("mix", "remix", "bootleg", "edit", "rmx", "remake", "cover", "mash")) and is_english(title):
                    title += " (Original Mix)"
            # If the result's information is totally different from the query, use the query
            if clear_artist(artist).lower() not in original_query.lower() and len(query_comps) > 1:
                artist = query_comps[0]
                title = query_comps[1]
        url = track_info['url']
        duration = track_info['duration']
        file_size = track_info['aid']
        file_name = u"{0} - {1}.mp3".format(artist, title)
        file_path = path + '/' + file_name.replace('/', ' & ')
        kbps = int(64 * round(float(file_size * 8 / 1024 / int(duration)) / 64))
        if not os.access(file_path, os.F_OK) or os.stat(file_path).st_size < file_size:
            # NSLog(u"Downloading: '{0}' ({1}MB, {2}, {3}kbps)".format(file_name, file_size / 1024 / 1024, fix_duration(duration), kbps))
            f = open(file_path, 'wb')
            progress = 0
            size_dl = 0
            block_sz = 8192
            u = open_url(url)
            while True:
                # Make a fancy progress bar
                print u"Downloading: {0}%".format(int(float(size_dl) / file_size * 100))
                buffer = u.read(block_sz)
                if not buffer:
                    break
                size_dl += len(buffer)
                f.write(buffer)
            f.close()
            output("Success: Track downloaded")
            if apply_tags:
                # NSLog("Applying tags")
                set_tags(artist, title, file_path)
        else:
            output("Failure: File already exists")


def set_tags(artist, title, file_path):
    """Update's the music file's tags using the information from either the match, the file itself, or the query.
    """
    audio = MP3(file_path, ID3=ID3)
    # Add ID3 tags if they doesn't exist
    try:
        audio.add_tags()
    except:
        pass
    audio.tags.update_to_v24() # Update the tags' version
    audio.tags.setall('TPE1', [TPE1(encoding=3, text=artist)]) # Set artist tag
    audio.tags.setall('TIT2', [TIT2(encoding=3, text=title)]) # Set title tag
    # Album
    if match and match.release:
        audio.tags.setall('TALB', [TALB(encoding=3, text=match.release)])
    elif not audio.tags.getall('TALB'): # If the file doesn't have the album tag, just use the cleared title
        audio.tags.add(TALB(encoding=3, text=clear_title(title, False, True)))
    elif clear_title(title, True) not in audio.tags.getall('TALB')[0].text[0]: # If the album tag is unrelated, replace it
        audio.tags.setall('TALB', [TALB(encoding=3, text=clear_title(title, False, True))])
    else:
        audio.tags.setall('TALB', [TALB(encoding=3, text=fix_album(audio.tags.getall('TALB')[0].text[0]))])
    audio.tags.delall('TPE2') # Clear album artist field
    audio.tags.delall('COMM') # Clear comment field
    audio.tags.delall('USLT') # Clear lyrics field
    audio.tags.delall('TIT1') # Clear grouping field
    audio.tags.delall('TCOM') # Clear composer field
    if match and match.number:
        audio.tags.setall('TRCK', [TRCK(encoding=3, text=match.number)]) # Set track number tag
    elif not audio.tags.getall('TRCK') or audio.tags.getall('TRCK')[0].text[0] == "1":
        audio.tags.setall('TRCK', [TRCK(encoding=3, text=u"1/1")]) # Set track number tag
    # If the match has cover art, download it and add it to the file
    if match and match.cover:
        image_path = u"{0}/{1} - {2}.jpg".format(path, artist, title)
        image = open(image_path,'wb')
        image.write(open_url(match.cover).read())
        image.close()
        audio.tags.setall('APIC', [APIC(encoding=3, mime='image/jpeg', type=3, desc=u"Cover", data=open(image_path).read())]) # Set cover
    # If not year tag was found, set either the match's year or current year
    if not audio.tags.getall('TDRC'):
        if match and match.year:
            audio.tags.setall('TDRC', [TDRC(encoding=3, text=str(match.year))]) # Set year
        else:
            audio.tags.setall('TDRC', [TDRC(encoding=3, text=str(time.strftime("%Y")))]) # Set year
    audio.save()
    if match and match.cover:
        os.remove(image_path) # Delete the cover image file


def sort_results(results):
    """Sort the results from VK by file size, bitrate, duration, and track version.
    """
    sorted_results = results[:]
    if sorted_results:
        total = len(sorted_results)
        correct_duration = None
        if match:
            # If not looking for a radio edit, use the match's duration as the correct one
            if match.duration and (match.duration > 180 or any(x in match.title for x in ("radio edit", "radio mix"))):
                correct_duration = int(match.duration)
                if min_kbps == 320:
                    step = 15
                elif min_kbps == 256:
                    step = 25
                else:
                    step = 40
        to_remove = []
        for i in range(total):
            track_info = sorted_results[i]
            duration = track_info['duration']
            name = fix_track_name(track_info['artist'], track_info['title']).encode('utf-8')
            size = track_info['aid']
            kbps = int(64 * round(float(size * 8 / 1024 / int(duration)) / 64))
            # Remove the file from list if it's too big
            if size > 30000000:
                # NSLog("#{0} Rejected: File '{1}' is too big ({2}MB)".format(i+1, name, size / 1024 / 1024))
                to_remove.append(i)
            # Remove the file from list if it has too low quality
            elif kbps < min_kbps:
                # NSLog("#{0} Rejected: File '{1}' has too low bitrate ({2}kbps)".format(i+1, name, kbps))
                to_remove.append(i)
            # Remove the file from list if its duration is wrong
            elif correct_duration != None and min_kbps != 128:
                if duration < correct_duration - step or duration > correct_duration + step:
                    # NSLog("#{0} Rejected: File '{1}' has wrong duration ({2}, correct: {3})".format(i+1, name,
                    # fix_duration(duration), fix_duration(int(match.duration))))
                    to_remove.append(i)
            # Remove the file from list if it's not the right mix
            elif is_remix and (not any(x in name.lower() for x in ("mix", "remix", "rmx", "edit", "bootleg", "mash")) or
            any(x in name.lower()  for x in ("(original", "(extended", "(radio", "(dub"))):
                # NSLog("#{0} Rejected: File '{1}' is the wrong version of the track".format(i+1, name))
                to_remove.append(i)
            elif not is_remix and (any(x in name.lower() for x in ("mix", "remix", "rmx", "edit", "bootleg", "mash")) and
            not any(x in name.lower()  for x in ("(original", "(extended", "(radio", "(dub"))):
                # NSLog("#{0} Rejected: File '{1}' is the wrong version of the track".format(i+1, name))
                to_remove.append(i)
            # If this result is good, look no further
            if i not in to_remove:
                for k in range(i+1, total):
                    to_remove.append(k)
                break
        to_remove = sorted(to_remove, reverse=True)
        for junk in to_remove:
            sorted_results.pop(junk)
        if not sorted_results:
            output("Failure: Nothing found")
    return sorted_results


def prepare_results(json_data):
    '''Retrieves the information for results from the list.
    '''    
    data = json.loads(json_data)
    results = data['response']
    results.pop(0) # Remove first unusable item from the list
    total = len(results)
    if total > 0:
        for i in range(total):
            print u"Analyzing {0}%".format(int(float(i+1) / total * 100))
            url = results[i]['url']
            meta = open_url(url).info()
            results[i]['artist'] = HTMLParser().unescape(results[i]['artist'])
            results[i]['title'] = HTMLParser().unescape(results[i]['title'])
            results[i]['aid'] = int(meta.getheaders("Content-Length")[0]) # Set the file size
    else:
        output("Failure: Nothing found")
    return results


def search_mb():
    musicbrainzngs.set_useragent('music-downloader', '0.1')
    criteria = {}
    if len(query_comps) > 1:
        criteria = {'artist': clear_comps[0], 'recording': clear_comps[1]}
    try:
        if criteria:
            recordings = musicbrainzngs.search_recordings(limit=10, **criteria)
        else:
            recordings = musicbrainzngs.search_recordings(limit=10, query=clear_query)
    except Exception as e:
        print "Failure: Something went wrong"
        sys.exit()
    for recording in recordings['recording-list']:
        yield get_mb_info(recording)


def get_mb_info(recording):
    track_number = None
    total_number = None
    track_id = None
    info = TrackInfo(recording['title'])
    info.source = "MusicBrainz"
    if recording.get('artist-credit'):
        artist_parts = []
        for el in recording['artist-credit']:
            if isinstance(el, basestring):
                artist_parts.append(el)
            else:
                artist_parts.append(el['artist']['name'])
        info.artist = " ".join(artist_parts)
    if recording.get('length'): info.duration = int(recording['length']) / (1000.0)
    if recording.get('release-list'):
        for release in recording.get('release-list'):
            if release.get('id'):
                info.cover = get_mb_cover(release['id'])
            if release.get('medium-list'):
                for medium in release['medium-list']:
                    if medium.get('track-list'):
                        for list in medium['track-list']:
                            if list.get('number'):
                                track_number = list.get('number')
                    if medium.get('track-count'):
                        total_number = medium.get('track-count')
                    if track_number and total_number:
                        break
            if release.get('title'):
                info.release = release.get('title')
            if release.get('date'):
                info.year = int(release.get('date').split('-')[0])
            if track_number and total_number:
                info.number = "{0}/{1}".format(track_number, total_number)
            else:
                info.number = "1/1"
            break
    info.decode()
    return info


def get_mb_cover(mbid):
    """ Make a Cover Art Archive request.
    """
    # Construct the full URL for the request, including hostname and query string
    path = ['release', mbid, "{0}-{1}".format('front', '500')]
    url = musicbrainzngs.compat.urlunparse((
        'http',
        'coverartarchive.org',
        '/%s' % '/'.join(path),
        '',
        '',
        ''
    ))
    p = urlparse(url)
    conn = httplib.HTTPConnection(p.netloc)
    conn.request('HEAD', p.path)
    resp = conn.getresponse()
    if resp.status == 307:
        opener = urllib2.build_opener(urllib2.HTTPRedirectHandler)
        request = opener.open(url)
        return request.url
    else:
        return None


def search_soundcloud():
    """Fetches results from Soundcloud for the given query.
    """
    # Create a client object with my app credentials
    client = soundcloud.Client(client_id="2eaab453dce03a7bca4b475e4132a163")
    # Create a list of TrackInfo objects.
    matches = []
    try:
        # Find all sounds for the given query
        tracks = client.get('/tracks', q=clear_query)
    except Exception as e:
        print "Failure: Something went wrong"
        sys.exit()
    # Stop after 10 results
    if len(tracks) > 10:
        results = 10
    else:
        results = len(tracks)
    for i in range(results):
        words = [comp.strip() for comp in tracks[i].title.split(' - ')]
        if len(words) > 1:
            artist = words[0]
            title = words[1]
        else:
            artist = tracks[i].user["username"]
            title = tracks[i].title
        # If the sound has a release date, use it for the year attribute, else use the date the sound was created
        if tracks[i].release_year:
            year = tracks[i].release_year
        else:
            year = tracks[i].created_at.split("/")[0]
        match = TrackInfo(title, artist, 'Soundcloud', tracks[i].duration / 1000, year)
        if tracks[i].artwork_url: match.cover = tracks[i].artwork_url.replace("large","t500x500")
        matches.append(match)
    return matches


class TrackInfo(object):
    def __init__(self, title, artist=None, source=None, duration=None, year=None, cover=None, release=None, number=None):
        self.title = title
        self.artist = artist
        self.source = source
        self.duration = duration
        self.year = year
        self.cover = cover
        self.release = release
        self.number = number

    # Work around a bug in python-musicbrainz-ngs
    def decode(self, codec='utf8'):
        """Ensure that all string attributes on this object are decoded
        to Unicode.
        """
        for fld in ['title', 'artist', 'cover', 'release', 'number']:
            value = getattr(self, fld)
            if isinstance(value, str): setattr(self, fld, value.decode(codec, 'ignore'))


def fix_track_name(artist=None, title=None, full=None):
    """Applies various replacements to the title and artist.
    """
    if not artist and not title and full:
        name = [comp.strip() for comp in full.split(' - ')]
        if len(name) > 1:
            artist = name[0]
            title = name[1]
        else: # If the query consists of one components, use recursion
            name[0] = fix_track_name(name[0], None)
            name[0] = fix_track_name(None, name[0])
            return " ".join(name[0].split())
    feat = None # Arist feature
    # Replacements for artist
    if artist:
        artist = make_replacements(artist).replace("/", " & ")
        if ":" in artist:
            lindex = string.find(artist, ":")
            artist = artist[lindex+1:].strip()
    # Replacements for title
    if title:
        title = make_replacements(title)
        # Lowercase each word except the first in title if it is not in English
        if not is_english(title):
            words = title.split()
            for i in range(len(words)):
                if i != 0:
                    words[i] = words[i].lower()
            title = " ".join(words)
        if any(x in title for x in (" feat.", "(feat.")):
            if "(feat." in title:
                lindex = string.find(title, "(feat.")
                rindex = string.find(title, ")", lindex)
                feat = title[lindex+1:rindex].rstrip()
            else:
                lindex = string.find(title, "feat.")
                rindex = string.find(title, "(", lindex)
                if rindex == -1:
                    feat = title[lindex:].rstrip()
                else:
                    feat = title[lindex:rindex].rstrip()
            if rindex == -1:
                title = title[0:lindex]
            else:
                if title[lindex-1] == " ":
                    lindex -= 1
                if rindex != -1 and rindex < len(title) - 1:
                    if title[rindex+1] == " ":
                        rindex += 1
                title = title[0:lindex] + " " + title[rindex+1:]
        # Check the insides of all parentheses in the string
        for a in re.compile(r'\([^()]*\)').findall(title):
            if not any(b in a.lower() for b in ("mix", "remix", "bootleg", "edit", "remake", "cover", "mash")):
                title = title.replace(a, "") # Remove redundant information
            else:
                # Capitalize words inside parentheses
                c = a.split('(', 1)[1].split(')')[0]
                if c:
                    title = title.replace(c, re.sub(r'(^|\s)(\S)', lambda x: x.group(1) + x.group(2).upper(), c))
        if ")" in title:
            index = string.rfind(title, ")")
            title = title[:index+1]
        if "www" in title.lower():
            index = string.find(title.lower(), "www")
            title = title[:index]
        title = title.strip()
    # Append feature to artist
    if artist and feat:
        artist += u" {0}".format(feat)
    if artist and title:
        result = u"{0} - {1}".format(artist.strip(), title.strip())
        return " ".join(result.split())
    elif artist:
        return " ".join(artist.split())
    else:
        return " ".join(title.split())


def make_replacements(s):
    s = re.sub(r'(^|\s)(\S)', lambda x: x.group(1) + x.group(2).upper(), s.replace('[','(').replace(']',')'))
    s = s.replace("Featuring","feat.").replace("featuring","feat.").replace(" Feat "," feat. ").replace(" Feat."," feat.").replace("(Feat.", "(feat.")
    s = s.replace(" Ft "," feat. ").replace(" Ft."," feat.").replace("(Ft.","(feat.").replace("(ft ","(feat. ").replace("(feat ", "(feat. ")
    s = s.replace(" Vs ", " vs. ").replace(" Vs.", " vs.").replace(" And ", " & ").replace("Dj", "DJ")
    s = s.replace("Rmx", "Remix").replace("Mash)", "Mashup)")
    return s


def clear_artist(s):
    if "feat." in s:
        index = string.find(s, "feat")
        s = s[0:index-1]
    return remove_separators(s)


def remove_separators(s):
    return " ".join(s.replace(",", " ").replace("&", " ").replace("/", " ").replace(".", " ").split())


def clear_title(s, clear=False, release=False):
    if (any(x in s.lower() for x in ("(original mix)", "(original edit)", "(dub mix)", "(radio mix)", "(radio edit)")) or
    (clear and "(" in s)):
        index = string.find(s, "(")
        s = s[:index].strip()
    elif any(x in s.lower() for x in ("remix", "mix", "edit", "rmx", "mash", "bootleg")) and not release:
        s = s.replace(" Remix", "").replace(" remix", "").replace(" Mix", "").replace(" mix", "").replace("mashup", "").replace(" Bootleg", "")
        s = s.replace(" Edit", "").replace(" edit", "").replace(" Rmx", "").replace(" rmx", "").replace("mash", "").replace(" bootleg", "")
    return remove_separators(s)


def fix_album(s):
    s = fix_track_name(None, s)
    if "-" in s:
        index = string.find(s, "-")
        s = s[0:index].strip()
    return s


def fix_duration(seconds):
    if seconds:
        m, s = divmod(seconds, 60)
        if m == 0:
            return u"{0}s".format(int(s))
        else:
            return u"{0}m{1}s".format(int(m), int(s))
    else:
        return None


def get_feat(matches):
    # If the track is featuring someone, find out who that is to later add him to the best match
    for match in matches:
        if "feat." in match.artist and clear_artist(match.artist) in query_comps[0]:
            return match.artist[string.find(match.artist, "feat."):]
    return None


def is_english(s):
    try:
        s.encode('ascii')
    except UnicodeEncodeError:
        return False
    return True


def open_url(url):
    start_time = time.time()
    while True:
        delay = round(time.time() - start_time, 2)
        if delay < 10:
            try:
                u = urllib2.urlopen(url)
                return u
            except urllib2.HTTPError as e:
                output(u"Connecting...")
                time.sleep(1)
        else:
            output("Failure: No internet connection")
            sys.exit()

def output(s):
    # NSLog(s)
    print s

main()