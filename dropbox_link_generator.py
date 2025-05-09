"""
dropbox_link_generator.py

Generates Dropbox share links for all .mp3 files in a specified Dropbox folder.

Instructions:
1. Install the Dropbox Python SDK:
   pip install dropbox
2. Get a Dropbox API access token:
   - Go to https://www.dropbox.com/developers/apps
   - Create an app and generate an access token (see README or Dropbox docs)
3. Set ACCESS_TOKEN below or use an environment variable.
4. Set LOCAL_DIR to your Dropbox-synced folder (e.g., /Users/dgasperut/Dropbox/OTE 2024)

Usage:
    python dropbox_link_generator.py
"""

import dropbox
import os

# === USER CONFIGURATION ===
ACCESS_TOKEN = os.environ.get('DROPBOX_ACCESS_TOKEN', 'sl.u.AFtpHSsgthSxP8sal-00QF3r12cD_m8uTVmLqdbsbRY93LXw9SUiskJ38JMjAQAcy9v-L8_mlxHRzn6l-tyRVxcCBn90IOIUu_yfH9Eyb3hB4P0LDPtO4pc2ndJMZ9knz9aZXjxGmaQvP483PfnFjYjJJv9CZinZRXPtbc_8pKoQhyLUgOBm4bi-XuYpplRPsQwWgtM5VgvsAml7mJs04n9ZlfLbWZ_ePs-pkFfWuW4WylcUruwdloY-9y1bvze09dhKaYCQM6QDCpaoTJu9TB_jspPabCS2gzdHXYYDFkgPAtQunM4im8-BBiREirIlDWSVXYg3qAyY6FOVS48buMv_WuZwCU8noVnwMWN1OiBcWDQGGUXLczM7ZeLAuT1954BxbcVBVsaX6Z__-zPii9V3BMgNQF68Zx6IplNstADH9Xygc9GWaATVVeSjAvAonjegLfzdSqDQLb3sV46JU5brfA0LD1MGUl4RO2xL6QbPm7U32o2N1YxZ6LoBNl7SKGdtv83rKkSafiZyhlZJK2bYGamWag2raHqkQLsojA4z-2wtKM8SbwT9gw3xRieGADhEq75oDtVCkNivOgt7OHXUXfDJdMtc0nGJJRy5QVLtu2aPsMmbwr3zDe8vBtEIGEnE38q93jAwnqdf1fro45U3EwCbW8Lf-6mZjyCz6qVDuLTvtzAoe0q6LdAPo_p1cdf2pd4moOH_K_1p4m0ro5Aj1YohE5R8AbWZrCBkh5q2zIx_fyTjiJf8TAs3I5z60g2H-qf959MlkyY_N5aHGYsAZiiKOzWIJd8EwzyLns8gX4Mf0vR10-FsIGuAqdIvCUelWeRVUpXwy_lBWPJJxhdMkGRR24CCRiIlU_jNddtGpzvEsrp8NlXz0f2dHKChadUus-rlUqXv4jS4B6LBmJWLv4QpbqKFiy8eZm2sJ81IqvmgZwhnpdAHwvNmmPn9EEYVoHBACrvdIleBR3sSY_RZ8j3mZj8fM_fEg6K0YizdMWCc1pASKQz9mxeUNKoA31w5OB15yQhbYMcWnuR_HzrPJ1GR4XLBBjGKaUsXxjpc-_1xQa9TiBvO0GcD9zGzRG9R1PaHvLuN0t1ncIykRsc8YMZCbrLDbhUTrfvHA030g6uBxQvn2lTCEDy40C862opz9qfBH2t0WYzQ3NE5KJewA0k9hrY1vVYAlrL1DHb-YMFXLo5Z4CCgMrg86TRQI7nKArgln_o1ebmBJE2Yeb3gat1BqYwaBePfs65VsYzWU4XbIr9hUIhvMDPjFYEn5rI')
LOCAL_DIR = '/Users/dgasperut/Dropbox/OTE 2024'
# =========================

def local_to_dropbox_path(local_path):
    # Assumes LOCAL_DIR is inside your Dropbox folder
    # Replace your local Dropbox root as needed
    dropbox_root = '/Users/dgasperut/Dropbox'
    return local_path.replace(dropbox_root, '')

def main():
    if ACCESS_TOKEN == 'PASTE_YOUR_ACCESS_TOKEN_HERE':
        print('Please set your Dropbox access token in the script or via the DROPBOX_ACCESS_TOKEN environment variable.')
        return
    dbx = dropbox.Dropbox(ACCESS_TOKEN)
    for root, dirs, files in os.walk(LOCAL_DIR):
        for file in files:
            if file.lower().endswith('.mp3'):
                local_path = os.path.join(root, file)
                dropbox_path = local_to_dropbox_path(local_path)
                try:
                    # Try to create a shared link (will fail if one exists)
                    shared_link_metadata = dbx.sharing_create_shared_link_with_settings(dropbox_path)
                    url = shared_link_metadata.url
                except dropbox.exceptions.ApiError as e:
                    # If link already exists, fetch it
                    if (e.error.is_shared_link_already_exists()):
                        links = dbx.sharing_list_shared_links(path=dropbox_path, direct_only=True).links
                        url = links[0].url if links else 'ERROR: No link found'
                    else:
                        url = f'ERROR: {e}'
                print(f'{local_path} -> {url}')

if __name__ == '__main__':
    main() 