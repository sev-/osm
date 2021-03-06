# -*- coding: utf-8 -*-
"""
Translation rules for VMap0 populated areas translation project done by GIS-Lab.info
http://gis-lab.info/qa/vmap0-settl-rus.html
"""

def translateAttributes(attrs):
	if not attrs: return
	
	tags = {}
	
	if attrs['title']:
		street = attrs['title'] + ' вулиця'
		tags = {'name':street}
		tags.update({'name:uk':street})
		tags.update({'highway':'primary'})
	else:
		tags.update({'highway':'unclassified'})

	tags.update({'source':'nadoloni.com import'})
	tags.update({'source_ref':'http://nadoloni.com'})
	id = str(int(attrs['id']));
	tags.update({'nadoloni:id':"streets_main:"+id})
	
	return tags