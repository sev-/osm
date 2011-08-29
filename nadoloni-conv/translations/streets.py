# -*- coding: utf-8 -*-
"""
Translation rules for VMap0 populated areas translation project done by GIS-Lab.info
http://gis-lab.info/qa/vmap0-settl-rus.html
"""

def translateAttributes(attrs):
	if not attrs: return
	
	tags = {}
	
	if attrs['title']:
		tags = {'name':attrs['title']}
		tags.update({'name:uk':attrs['title']})
		tags.update({'name:ru':attrs['title_ru']})

	if float(attrs['style']) > 30:
		tags.update({'highway':'secondary'})
	elif float(attrs['style']) > 25:
		tags.update({'highway':'tertiary'})
	else:
		tags.update({'highway':'residential'})

	tags.update({'source':'nadoloni.com import'})
	tags.update({'source_ref':'http://nadoloni.com'})
	id = str(int(attrs['id']));
	tags.update({'nadoloni:id':"streets:"+id})
	
	return tags