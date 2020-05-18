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
						print("Info: Führende 00 tel:", val, landesvorwahl + val[2:], vcard)
						val = landesvorwahl + val[2:]
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
#				print("incomplete", vcard)
				pass

def main(argv):
	if sys.hexversion < 0x03050000:
		parser = argparse.ArgumentParser()
	else:
		parser = argparse.ArgumentParser(allow_abbrev=False)
	parser.add_argument("-i", metavar="contacts.vcf", help="input file", required=True)
	parser.add_argument("-o", metavar="/target/directory", help="output dir", required=True)
	args, unknown = parser.parse_known_args()
	if len(unknown) > 0:
		print("unknown arguments:", unknown)
		parser.print_help()
		sys.exit(1)

	inputfile = args.i
	outputdir = args.o
	print("android-contacts.vcf ist '%s'" % inputfile)
	print("Telefonbuch Verzeichnis ist '%s'" % outputdir)

	lese_vcf(inputfile)
	if len(telefonbuch) > 0:
		schreibe_verzeichnis(outputdir)
	print(len(telefonbuch), "Nummern")

if __name__ == "__main__":
	main(sys.argv[1:])
