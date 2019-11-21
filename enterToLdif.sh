USER_UID=usuario1
OU=people
DCS=hoth # Domain Controller Primary
DCP=ally # Domain Contoller Secondary
echo "dn: uid=$USER_UID,ou=$OU,dc=$DCS,dc=$DCP" >> test.ldif
