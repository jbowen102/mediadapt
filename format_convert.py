import os
import subprocess
import glob

from idevice_media_offload import date_compare
from idevice_media_offload import pic_categorize_tool


# dir path where this script is stored
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# https://stackoverflow.com/questions/29768937/return-the-file-path-of-the-file-not-the-current-directory


def convert_heif(heif_path, delete_heif=False):
    """Use heif-convert bash tool to convert heif file to jpg."""
    heif_name = os.path.basename(heif_path)
    file_ext = os.path.splitext(heif_path)[-1]
    file_no_ext = os.path.splitext(heif_name)[0]

    if file_ext.upper() != ".HEIC":
        raise Exception("convert_heif() only accepts HEIC files.")

    # Can't let bash tool handle collisions because it can't prompt user when
    # its output is suppressed.
    for ext_style in [".jpg", ".JPG", ".JPEG"]:
        converted_filename = file_no_ext + ext_style
        converted_path = os.path.join(os.path.dirname(heif_path), converted_filename)
        if os.path.exists(converted_path):
            print("Can't convert %s (JPG version already exists here)" % heif_name)
            return None

    converted_filepath = os.path.splitext(heif_path)[0] + ".jpg"
    print("Attempting to convert %s" % heif_name)
    CompProc = subprocess.run(["heif-convert", heif_path, converted_filepath],
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # bash output suppressed. No prompts in convert_heif.
    # converts file and puts output in original file's directory

    # Check for success
    if CompProc.returncode == 0:
        print("\tSUCCESSFUL CONVERSION: %s -> %s"
                            % (heif_name, os.path.basename(converted_filepath)))
        transfer_exif_comment(heif_path, converted_filepath)
        if delete_heif:
            os.remove(heif_path)
        return converted_filepath
    else:
        print("\tFAILED TO CONVERT %s " % heif_name)
        return None

def convert_webp(webp_path, delete_webp=False):
    """Use bash script convert_webp to convert webp to jpg or gif.
    delete_webp parameter determines if webp file gets deleted after conversion.
    If conversion fails, webp file not deleted."""

    webp_name = os.path.basename(webp_path)
    file_ext = os.path.splitext(webp_path)[-1]
    file_no_ext = os.path.splitext(webp_name)[0]

    if file_ext.upper() != ".WEBP":
        raise Exception("convert_webp() only accepts WEBP files.")

    # Check if two files w/ same name already exist in the directory.
    # Can't let bash script handle collisions because it can't prompt user when
    # its output is suppressed.
    wildcard_filename = file_no_ext + "." + "*"
    wildcard_path = os.path.join(os.path.dirname(webp_path), wildcard_filename)
    matches = glob.glob(wildcard_path)
    if len(matches) > 1:
        print("Can't convert %s (File with same name and different "
                                        "extension exists here)" % webp_name)
        return None

    print("Attempting to convert %s" % webp_name)
    CompProc = subprocess.run(["%s/convert_webp.sh" % SCRIPT_DIR, webp_path],
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # bash output suppressed. No prompts in convert_webp.
    # converts file and puts output in original file's directory

    # Check for success
    if CompProc.returncode == 0:
        # Could convert to either jpg or gif
        # Find matches again now that there are two
        matches = glob.glob(wildcard_path)
        # Find non-webp one by deducting sets
        # https://stackoverflow.com/a/21502564
        converted_filepath = ( set(matches) - set([webp_path]) ).pop()

        if delete_webp:
            os.remove(webp_path)

        print("\tSUCCESSFUL CONVERSION: %s -> %s"
                            % (webp_name, os.path.basename(converted_filepath)))
        return converted_filepath
    else:
        print("\tFAILED TO CONVERT %s " % webp_name)
        return None


def write_exif_comment(file_path, comment):
    """Wrapper for bash script write_exif_comment.
    Does not check for existence of a comment first."""
    CompProc = subprocess.run(["%s/write_exif_comment.sh" % SCRIPT_DIR, file_path,
                str(comment)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if CompProc.returncode != 0:
        raise Exception("Call to write_exif_comment failed.")


def transfer_exif_comment(from_path, to_path):
    """Transcribe any comment/caption found in original file.
    """
    img_comment = date_compare.get_comment(from_path)
    if img_comment:
        print("Transferring EXIF comment '%s'" % img_comment)
        write_exif_comment(to_path, img_comment)


def open_img_source(file_path):
    """Extract and open source URL from pic metadata if one stored there.
    """
    img_comment = date_compare.get_comment(file_path)

    if not img_comment:
        print("No EXIF comment found.\n")
    elif "http" in img_comment.lower():
        # Isolate URL. Replace commas w/ spaces then split comment by spaces.
        img_src_url = [word for word in img_comment.replace(",", " ").split(" ")
                                                        if "http" in word][0]
        # Open URL in browser
        pic_categorize_tool.os_open(img_src_url)
    else:
        print("No URL found in EXIF comment:\n\t%s" % img_comment)


def convert_gif_to_mp4(gif_path):
    """Wrapper for bash script trim_to_mp4 that also displays file sizes."""

    dir_name = os.path.dirname(gif_path)
    CompProc = subprocess.run(["%s/trim_to_mp4.sh" % SCRIPT_DIR, gif_path],
                                                    stderr=subprocess.STDOUT)
    # bash prompts passed to user - no stdout= param passed to subprocess.run() call.

    if CompProc.returncode == 0:
        converted_filename = os.path.splitext(gif_path)[0] + ".mp4"
        converted_filepath = os.path.join(dir_name, converted_filename)

        gif_size = os.path.getsize(gif_path)
        mp4_size = os.path.getsize(converted_filepath)

        print("\t%s  ->  %s  (%.2fx)" %
                (humanbytes(gif_size), humanbytes(mp4_size), mp4_size/gif_size))

    else:
        print("\tFAILED TO CONVERT")


# Call bash convert script
def convert_all_webx(dir_name, webx_type=None, delete_webx=False):
    """Use bash scripts convert_webp or trim_to_mp4 to convert either webp or
    webm files in a directory.
    *.webp (animated) ->  *.gif
    *.webp (static)   ->  *.jpg
    *.webm            ->  *.mp4
    "type" parameter is either 'webp' or 'webm'
    "delete_webx" parameter determines if webx files get deleted after conversions.
    If conversion fails, webx file not deleted.
    """
    webx_accum_size = 0
    output_accum_size = 0

    file_list = os.listdir(dir_name)
    if not webx_type:
        # convert both types
        webx_ext = [".webp", ".webm"]
    elif webx_type.lower() in ["webp", ".webp"]:
        webx_ext = [".webp"]
    elif webx_type.lower() in ["webm", ".webm"]:
        webx_ext = [".webm"]
    else:
        raise Exception("Unrecognized webx type. Recognized types: webp, webm")

    for file in file_list:
        og_path = os.path.join(dir_name, file)
        file_ext = os.path.splitext(file)[1].lower()
        if file_ext in webx_ext:
            # Check for existing converted file
            file_no_ext = os.path.splitext(file)[0]
            wildcard_filename = file_no_ext + "." + "*"

            # Check if two files w/ same name already exist in the directory.
            # Can't let bash script handle collisions because it
            # can't prompt user when its output is suppressed.
            matches = glob.glob(os.path.join(dir_name, wildcard_filename))
            if len(matches) > 1:
                print("Skipping: %s (File with same name and different "
                                                "extension exists here)" % file)
            else:
                print("Converting: %s" % file)
                if file_ext == ".webp":
                    CompProc = subprocess.run(["%s/convert_webp.sh" % SCRIPT_DIR, og_path],
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                    # bash output suppressed. No prompts in convert_webp.
                elif file_ext == ".webm":
                    CompProc = subprocess.run(["%s/trim_to_mp4.sh" % SCRIPT_DIR, og_path],
                                                    stderr=subprocess.STDOUT)
                    # bash prompts passed to user - no stdout= param passed to subprocess.run() call.

                # Check for success
                if CompProc.returncode == 0:
                    if file_ext == ".webp":
                        # Find matches again now that there are two
                        # Can't do this above because set.pop() will fail if conversion failed.
                        matches = glob.glob(os.path.join(dir_name, wildcard_filename))
                        # Find non-webx one by deducting sets
                        # https://stackoverflow.com/a/21502564
                        converted_filepath = ( set(matches) - set([og_path]) ).pop()

                    elif file_ext == ".webm":
                        converted_filepath = os.path.join(dir_name, file_no_ext + ".mp4")

                    webx_size = os.path.getsize(og_path)
                    output_size = os.path.getsize(converted_filepath)

                    webx_accum_size += webx_size
                    output_accum_size += output_size

                    print("\t%s  ->  %s  (%.2fx)" %
                                (humanbytes(webx_size), humanbytes(output_size),
                                                        output_size/webx_size))
                    if delete_webx:
                        os.remove(os.path.join(dir_name, file))

                else:
                    print("\tFAILED TO CONVERT")

    if webx_accum_size: # if no files found, will get div by zero
        print("\nOverall:\n\t%s  ->  %s  (%.2fx)" %
                (humanbytes(webx_accum_size), humanbytes(output_accum_size),
                                            output_accum_size/webx_accum_size))
    else:
        print("\nNo %s files found to convert in %s" % (", ".join(webx_ext), dir_name))


# humanbytes() copied from here (slight formatting modification by me):
# https://stackoverflow.com/a/21502564
def humanbytes(B):
   'Return the given bytes as a human friendly KB, MB, GB, or TB string'
   B = float(B)
   KB = float(1024)
   MB = float(KB ** 2) # 1,048,576
   GB = float(KB ** 3) # 1,073,741,824
   TB = float(KB ** 4) # 1,099,511,627,776

   if B < KB:
      return '{0} {1}'.format(B,'Bytes' if 0 == B > 1 else 'Byte')
   elif KB <= B < MB:
      return '{0:6.2f} KB'.format(B/KB)
   elif MB <= B < GB:
      return '{0:6.2f} MB'.format(B/MB)
   elif GB <= B < TB:
      return '{0:6.2f} GB'.format(B/GB)
   elif TB <= B:
      return '{0:6.2f} TB'.format(B/TB)

# tests = [1, 1024, 500000, 1048576, 50000000, 1073741824, 5000000000, 1099511627776, 5000000000000]
#
# for t in tests: print '{0} == {1}'.format(t,humanbytes(t))
