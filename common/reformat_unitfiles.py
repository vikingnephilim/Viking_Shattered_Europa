import os
import re

wd = os.path.dirname(os.path.realpath(__file__))
folder = os.path.join(wd, 'common', 'units')
out = input("Choose output folder (leave empty to overwrite): ")
if out == '':
	out = ['common', 'units']
else:
	out = [out,]
output = os.path.join(wd, *out)

if not os.path.isdir(output):
    os.makedirs(output)

re_history = re.compile(R"^[0-9]+\.[0-9]+\.[0-9]+")

files = [f for f in os.listdir(folder) if '-' in f]

for fil in files:
	with open(os.path.join(folder, fil), 'r') as f:
		tab = 0
		token = ''
		tokens = []
		for line in f.readlines():
			if line.strip(' \t') == '\n':
				continue
			token += line
			if '#' in line:
				line = line[0:line.find('#')]
			if '{' in line or '}' in line:
				tab += line.count('{')
				tab -= line.count('}')
			if tab == 0 and not token == '':
				tokens.append(token)
				token = ''
		if not tab == 0:
			print("Brace error in "+fil+" - final brace count "+tab)

	t_govern = []
	t_govern_list = ('type', 'unit_type', 'maneuver')
	t_demo = []
	t_demo_list = ('offensive_fire', 'defensive_fire')
	t_eco = []
	t_eco_list = ( 'offensive_shock', 'defensive_shock')
	t_disco = []
	t_disco_list = ( 'offensive_morale', 'defensive_morale')
	t_comment = []

	for t in tokens:
		if t.lstrip(' \t').startswith('#'):
			t_comment.append(t)
		elif t.startswith(t_disco_list):
			t_disco.append(t)
		elif t.startswith(t_demo_list):
			t_demo.append(t)
		elif t.startswith(t_eco_list):
			t_eco.append(t)
		else:
			t_govern.append(t)

	with open(os.path.join(output, fil), 'w') as f:
		for t in t_comment:
			f.write(t)
		f.write("\n# Unit Type & Maneuver\n#=========================\n")
		for t in t_govern:
			f.write(t)
		f.write("\n# Fire Pips\n#=========================\n")
		for t in t_demo:
			f.write(t)
		f.write("\n# Shock Pips\n#=========================\n")
		for t in t_eco:
			f.write(t)
		f.write("\n# Morale Pips\n#=========================\n")
		for t in t_disco:
			f.write(t)