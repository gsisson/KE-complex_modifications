#  grep -v ^main |

srcdir="src/json"
pubdir="public/json"
kdir="$HOME/.config/karabiner/assets/complex_modifications"

f1="emacs_key_bindings.json.rb"
f2="emacs_key_bindings_GLENN.json.rb"

echo "# creating ${srcdir}/${f2}..."
echo "#    (from ${srcdir}/${f1})"
cat ${srcdir}/${f1} |
  sed \
    -e 's:puts JSON.pretty_generate(:return {:' \
    -e 's:^  ):}:' \
    -e 's:^main::' \
  > ${srcdir}/${f2}

cat >> ${srcdir}/${f2} << EOF
def main2
  data=main
  data['title'] = data['title'].sub(')',') <---- GLENN')
  data['maintainers'] = ['gsisson']
  rules = data['rules'].select do |item|
    # Keep only the two rule groups for C- key stuff
    #   C-  key stuff: "Emacs key bindings [control+keys] (rev 10)",
    #   C-  key stuff: "For Visual Studio Code: Emacs key bindings [control+keys] (rev 10)",
    # which means git rid of these rule groups:
    #   C-X key stuff: "Emacs key bindings [C-x key strokes] (rev 2)",
    #   OPT key stuff: "For Visual Studio Code: Emacs key bindings [option+keys] (rev 5)",
    item['description'] =~ /Emacs key bindings \[control\+keys\]/
  end
  # Should have kept just 2 rule groups
  if rules.size != 2
    abort("did not find 'description'!!")
  end

  # Add my name at end of both rule groups we kept
  [0,1].each do |index|
    rules[index]['description'] = rules[index]['description'].sub(')',') <---- GLENN')
  end
  data['rules'] = rules

  [0,1].each do |index|
    manipulators = data['rules'][index]['manipulators'].reject do |item|
      # toss out the ^[ and ^] key stroke rules from the group
      key_code = item['from']['key_code']
      key_code == "open_bracket" || key_code == "close_bracket"
    end
    # should have dropped 2 rules from the rule group
    if manipulators.size != data['rules'][index]['manipulators'].size - 2
      abort("did not find 'open/close_bracket'!!")
    end
    data['rules'][index]['manipulators'] = manipulators
  end

  # Now get rid of the "optional" meta keys so that Karabiner ONLY handles control characters hit all by them selves
  # cat public/json/emacs_key_bindings_GLENN.json | jq '.rules[].manipulators[].from.modifiers.optional'
  data['rules'].each do | rule |
    rule['manipulators'].each do |manipulator|
      optional = manipulator['from']['modifiers']['optional']
      optional.clear
    end
  end

  puts JSON.pretty_generate(data)
end

main2
EOF

ruby $srcdir/$f2 > $pubdir/${f2%.rb}
if ! cmp --silent ${pubdir}/${f2%.rb} ${kdir}/${f2%.rb}; then
  echo "#############################################################"
  echo "###  Generated file is different from the installed one!  ###"
  echo "#############################################################"
  echo "#     Run this to use the new one:"
  echo "#       cp ${pubdir}/${f2%.rb} ${kdir/$HOME/~}/${f2%.rb}"
  echo "#"
else
  echo
  echo "######################################"
  echo "###   installed file is the same   ###"
  echo "######################################"
fi

cat << EOF

# To install in Karabiner
# - copy the file to Karabiner location:
#   - cp ${pubdir}/${f2%.rb} ${kdir/$HOME/~}/${f2%.rb}"
# - start Karabiner
# - go to the 'complex modifications' tab
# - if the rule is already there, delete it:
#   [REMOVE] this one: "Emacs key bindings [control+keys] (rev 10) <---- GLENN"
# - then add it back
#   [ADD RULE]
#   [ENABLE] this one: "Emacs key bindings [control+keys] (rev 10) <---- GLENN"
#   and MAYBE enable this: "For Visual Studio Code: Emacs key bindings [control+keys] (rev 10) <---- GLENN"

# Finally, if you want to compare the rules, run
  ruby src/json/emacs_key_bindings.json.rb > public/json/emacs_key_bindings.json
  vdiff public/json/emacs_key_bindings.json $pubdir/${f2%.rb}
EOF
