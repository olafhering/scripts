#!/usr/bin/python3
# vim: ts=2 shiftwidth=2 noexpandtab number

# Export just phone number and full name from an Android contacts.vcf
# Export target is a directory filled with phone numbers as directory
# Each phone number directory contains at least one empty file based on full name

# The phone numbers are the index, each one will exists just once
# The name may appear several times in more than one phone number
# More than one name might be assigned to a single phone number


import argparse
import errno
import getopt
import string
import os
import sys
import vobject

landesvorwahl = "49"
datum = 1234567890
minimal_laenge = 7
telefonbuch = {}

def schreibe_verzeichnis(path):
	try:
		os.mkdir(path)
	except OSError as error:
		if error.errno != errno.EEXIST:
			print("FATAL", error)
			return
	# create directory for each phone number
	for tel in telefonbuch:
		d = os.path.join(path, tel)
		os.makedirs(d, exist_ok=True)
		# create empty file for each full name
		for fn in telefonbuch[tel]:
			n = os.path.join(d, fn)
			open(n, 'a').close()
			os.utime(n, (datum, datum))
		os.utime(d, (datum, datum))

def lese_vcf(path):
	with open(path) as source_file:
		for vcard in vobject.readComponents(source_file, allowQP=True):
			fns = {}
			telefon = {}
			
			# extract full name from each vcard entry
			if 'fn' in vcard.contents.keys():
				for fn in vcard.contents['fn']:
					val = fn.valueRepr()
					if val in fns:
						print("Doppelter Wert fn:", val, vcard)
					else:
						fns[val] = 1

			# extract phone number from each vcard entry
			if 'tel' in vcard.contents.keys():
				for tel in vcard.contents['tel']:
					val = tel.valueRepr()
					# remove spaces and dashes to get a plain number
					val = val.replace(' ', '')
					val = val.replace('-', '')

					# ignore short service numbers
					if len(val) < minimal_laenge:
						continue

					# strip leading international call prefix
					if val.startswith('+'):
						val = val[1:]
						if val.startswith('49'):
							pass
						elif val.startswith('1'): # US
							pass
						elif val.startswith('27'): # Südafrika
							pass
						elif val.startswith('33'): # Frankreich
							pass
						elif val.startswith('34'): # Spanien
							pass
						elif val.startswith('353'): # Irland
							pass
						elif val.startswith('359'): # Bulgarien
							pass
						elif val.startswith('380'): # Ukraine
							pass
						elif val.startswith('39'): # Italien
							pass
						elif val.startswith('40'): # Rumänien
							pass
						elif val.startswith('41'): # Schweiz
							pass
						elif val.startswith('420'): # Tschechien
							pass
						elif val.startswith('43'): # Östereich
							pass
						elif val.startswith('44'): # UK
							pass
						elif val.startswith('48'): # Polen
							pass
						elif val.startswith('509'): # Haiti
							pass
						elif val.startswith('7'): # Russland
							pass
						else:
							print("Info: Landesvorwahl ...:", val, vcard)
					# translate international call prefix
					elif val.startswith('00'):
						print("Info: Führende 00 tel:", val, val[2:], vcard)
						val = val[2:]
					# translate national call prefix
					elif val.startswith('0'):
						print("Info: Führende 0 tel:", val, landesvorwahl + val[1:], vcard)
						val = landesvorwahl + val[1:]
					# record this number for this iteration
					if val not in telefon:
						telefon[val] = True

			if len(telefon) and len(fns):
				just_added = []
				# all known numbers from this iteration
				for tel in telefon.keys():
					# single list of names for this number
					if (tel in telefonbuch) and (tel not in just_added):
						names = telefonbuch[tel]
					else:
						names = []
					just_added.append(tel)
					for name in list(fns):
						name = name.replace('/', '|')
						if name not in names:
							names.append(name)
					telefonbuch[tel] = names

			else:
				if False:
					print("incomplete", vcard)

def schreibe_vcf(output_path):
	vcs = []
	nummern = list(telefonbuch.keys())
	for tel in sorted(nummern):
		vc = vobject.vCard()
# <FN{'CHARSET': ['UTF-8']}Möchte ein Ü kaufen>
# Wo ist das ENCODING ?!
		vc.add('fn').value  = telefonbuch[tel][0]
		vc.add('tel').value = "+" + tel
		vcs.append(vc)
	with open(output_path, 'w', newline='') as f:
		for vc in vcs:
			f.write(vc.serialize())


def lese_verzeichnis(input_path):
	for tel in os.scandir(input_path):
		fns = []
		if not tel.is_dir():
			print(tel.path, "is not a directory", file=sys.stderr)
			sys.exit(1)
		if not tel.name.isdigit():
			print(tel.path, "is not a phone number", file=sys.stderr)
			sys.exit(1)
		for fn in os.scandir(tel.path):
			if not fn.is_file():
				print(fn.path, "is not a full name", file=sys.stderr)
				sys.exit(1)
			fns.append(fn.name.replace('|', '/'))
		if not len(fns):
			print(tel.path, "no entry for full name", file=sys.stderr)
			sys.exit(1)
		telefonbuch[tel.name] = fns
		

def vcf_nach_verzeichnis(input_path, output_path):
	if os.path.exists(output_path) and not os.path.isdir(output_path):
		print(output_path, "is not a directory", file=sys.stderr)
		sys.exit(1)

	print("android-contacts.vcf ist '%s'" % input_path)
	print("Telefonbuch Verzeichnis ist '%s'" % output_path)

	lese_vcf(input_path)
	if len(telefonbuch) > 0:
		schreibe_verzeichnis(output_path)
	print(len(telefonbuch), "Nummern")


def verzeichnis_nach_vcf(input_path, output_path):
	if os.path.exists(output_path) and not os.path.isfile(output_path):
		print(output_path, "is not a file", file=sys.stderr)
		sys.exit(1)

	print("Telefonbuch Verzeichnis ist '%s'" % input_path)
	print("android-contacts.vcf ist '%s'" % output_path)

	lese_verzeichnis(input_path)
	if len(telefonbuch) > 0:
		schreibe_vcf(output_path)
	print(len(telefonbuch), "Nummern")


def main(argv):
	if sys.hexversion < 0x03050000:
		parser = argparse.ArgumentParser()
	else:
		parser = argparse.ArgumentParser(allow_abbrev=False)
	parser.add_argument("-i", metavar="contacts.vcf or /target/directory", help="input file, or output directory", required=True)
	parser.add_argument("-o", metavar="/target/directory, or contacts.vcf", help="output dir, or input file", required=True)
	args, unknown = parser.parse_known_args()
	if len(unknown) > 0:
		print("unknown arguments:", unknown)
		parser.print_help()
		sys.exit(1)

	input_path = args.i
	output_path = args.o
	if os.path.isfile(input_path):
		vcf_nach_verzeichnis(input_path, output_path)
	elif os.path.isdir(input_path):
		verzeichnis_nach_vcf(input_path, output_path)

if __name__ == "__main__":
	main(sys.argv[1:])
