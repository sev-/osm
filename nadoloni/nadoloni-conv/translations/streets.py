# -*- coding: utf-8 -*-
"""
Translation rules for VMap0 populated areas translation project done by GIS-Lab.info
http://gis-lab.info/qa/vmap0-settl-rus.html
"""

def translateAttributes(attrs):
	if not attrs: return
	
	tags = {}
	
	if attrs['title_ua']:
		tags = {'name':attrs['title_ua']}
		tags.update({'name:uk':attrs['title_ua']})
		tags.update({'name:ru':attrs['title_ru']})

	width = float(attrs['width']) * 0.2
	tags.update({'width':str(width)})

	if attrs['title_ua']:
		tags.update({'highway':'residential'})
	elif width <= 1.2:
		tags.update({'highway':'path'})
	else:
		tags.update({'highway':'unclassified'})

	tags.update({'source':'nadoloni.com import'})
	tags.update({'source_ref':'http://nadoloni.com'})
	id = str(int(attrs['id']));
	tags.update({'nadoloni:id':"streets:"+id})
	
	return tags
