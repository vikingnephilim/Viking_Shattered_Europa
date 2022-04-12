import os
import re

wd = os.path.dirname(os.path.realpath(__file__))
folder = os.path.join(wd, 'history', 'countries')
out = input("Choose output folder (leave empty to overwrite): ")
if out == '':
	out = ['history', 'countries']
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
	t_govern_list = ('government', 'add_government_reform')
	t_demo = []
	t_demo_list = ('capital', 'fixed_capital', 'primary_culture', 'add_accepted_culture', 'technology_group', 'mercantilism')
	t_eco = []
	t_eco_list = ( 'religion', 'unlock_cult', 'religious_school')
	t_disco = []
	t_disco_list = ('1300.01.01
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
		f.write("\n# Governance\n#=========================\n")
		for t in t_govern:
			f.write(t)
		f.write("\n# Demographic\n#=========================\n")
		for t in t_demo:
			f.write(t)
		f.write("\n# Religion\n#=========================\n")
		for t in t_eco:
			f.write(t)
		f.write("\n# Ruler\n#=========================\n")
		for t in t_disco:
			f.write(t)