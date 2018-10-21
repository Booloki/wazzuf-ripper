#!/bin/bash

# Wazzuf Ripper internationalization update script (fr language only)
#
# cf. http://www.gnu.org/software/gettext/manual/gettext.html
#
# Dependency: gettext 


## Variables

I18N="fr"
TEXT_ENCODING="UTF-8"
CODE_LANGUAGE="Shell"
COPYRIGHT_HOLDER="Nicolas Perrin"
BUGS_EMAIL="booloki@lokizone.net"
SCRIPT_DIR="scripts"
LOCALE_DIR="locale"
SCRIPT_FILES="wazzuf-conf-generator wazzuf-ripper"


## Script

cd "${SCRIPT_DIR}" || exit 1

for SCRIPT_NAME in ${SCRIPT_FILES}; do

  # Extracts the tags and creates the template file (e.g. *.pot file)
  echo "*** template update ***"
  xgettext -L "${CODE_LANGUAGE}" --from-code="${TEXT_ENCODING}" --copyright-holder="${COPYRIGHT_HOLDER}" --msgid-bugs-address="${BUGS_EMAIL}" -d "${SCRIPT_NAME}" "${SCRIPT_NAME}" -o "../${LOCALE_DIR}/${SCRIPT_NAME}.pot"

  # Updates a .po file with changes from the .pot file
  echo "*** po merge ***"
  msgmerge -U "../${LOCALE_DIR}/${I18N}/${SCRIPT_NAME}.po" "../${LOCALE_DIR}/${SCRIPT_NAME}.pot"

  # Convert to .mo file
  echo "*** mo create ***"
  msgfmt "../${LOCALE_DIR}/fr/${SCRIPT_NAME}.po" -o "../${LOCALE_DIR}/${I18N}/LC_MESSAGES/${SCRIPT_NAME}.mo"

done
