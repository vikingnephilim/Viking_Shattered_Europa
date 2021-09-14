import os
import re

wd = os.path.dirname(os.path.realpath(__file__))
folder = os.path.join(wd, 'history', 'provinces')
out = input("Choose output folder (leave empty to overwrite): ")
if out == '':
	out = ['history', 'provinces']
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
	t_govern_list = ('owner', 'controller', 'add_core', 'is_city', 'tribal_owner', 'native_size', 'native_ferocity', 'native_hostileness')
	t_demo = []
	t_demo_list = ('capital', 'culture', 'religion', 'hre',)
	t_eco = []
	t_eco_list = ('trade_goods', 'base_tax', 'base_production', 'base_manpower', 'center_of_trade', 'extra_cost')
	t_disco = []
	t_disco_list = ('discovered_by',)
	t_histo = []
	t_other = []
	t_comment = []

	for t in tokens:
		if re.match(re_history, t):
			t_histo.append(t)
		elif t.lstrip(' \t').startswith('#'):
			t_comment.append(t)
		elif t.startswith(t_disco_list):
			t_disco.append(t)
		elif t.startswith(t_demo_list):
			t_demo.append(t)
		elif t.startswith(t_eco_list):
			t_eco.append(t)
		elif t.startswith(t_govern_list):
			t_govern.append(t)
		else:
			t_other.append(t)
			
	with open(os.path.join(output, fil), 'w') as f:
		for t in t_comment:
			f.write(t)
		f.write("\n# Governance\n#=========================\n")
		for t in t_govern:
			f.write(t)
		f.write("\n# Demographic\n#=========================\n")
		for t in t_demo:
			f.write(t)
		f.write("\n# Economic\n#=========================\n")
		for t in t_eco:
			f.write(t)
		f.write("\n# Discovery\n#=========================\n")
		for t in t_disco:
			f.write(t)
		f.write("\n# History\n#=========================\n")
		for t in sorted(t_histo):
			f.write(t)
		f.write("\n#=========================\n")
		for t in t_other:
			f.write(t)