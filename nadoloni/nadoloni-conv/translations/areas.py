# -*- coding: utf-8 -*-
"""
Translation rules for VMap0 populated areas translation project done by GIS-Lab.info
http://gis-lab.info/qa/vmap0-settl-rus.html
"""

def translateAttributes(attrs):
	if not attrs: return
	
	tags = {}
	
	if attrs['title_ua']:
		tags.update({'name':attrs['title_ua']})
		tags.update({'name:uk':attrs['title_ua']})
		tags.update({'name:ru':attrs['title_ru']})
		tags.update({'name:en':attrs['title_en']})

	if attrs['type'] == 'stadium':
		tags.update({'leisure':attrs['type']})
	elif attrs['type'] == 'parking':
		tags.update({'amenity':attrs['type']})
	elif attrs['type'] == 'urban':
		tags.update({'landuse':'residential'})
		tags.update({'residential':'rural'})
	elif attrs['type'] == 'wood':
		tags.update({'landuse':'forest'})
	else:
		tags.update({'landuse':attrs['type']})

	tags.update({'source':'nadoloni.com import'})
	tags.update({'source_ref':'http://nadoloni.com'})
	id = str(int(attrs['id']));
	tags.update({'nadoloni:id':"areas:"+id})
	
	return tags
