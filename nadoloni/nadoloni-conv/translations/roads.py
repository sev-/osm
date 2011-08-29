# -*- coding: utf-8 -*-
"""
Translation rules for VMap0 populated areas translation project done by GIS-Lab.info
http://gis-lab.info/qa/vmap0-settl-rus.html
"""

def translateAttributes(attrs):
	if not attrs: return
	
	tags = {}
	
	if float(attrs['style']) > 30:
		tags.update({'highway':'tertiary'})
	elif float(attrs['style']) > 20:
		tags.update({'highway':'unclassified'})
	else:
		tags.update({'highway':'service'})

	tags.update({'source':'nadoloni.com import'})
	tags.update({'source_ref':'http://nadoloni.com'})
	id = str(int(attrs['id']));
	tags.update({'nadoloni:id':"roads:"+id})
	
	return tags