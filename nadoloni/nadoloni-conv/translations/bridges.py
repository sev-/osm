# -*- coding: utf-8 -*-
"""
Translation rules for VMap0 populated areas translation project done by GIS-Lab.info
http://gis-lab.info/qa/vmap0-settl-rus.html
"""

def translateAttributes(attrs):
	if not attrs: return
	
	tags = {}
	
	tags.update({'highway':'road'})
	tags.update({'bridge':'yes'})
	tags.update({'layer':'1'})
	tags.update({'source':'nadoloni.com import'})
	tags.update({'source_ref':'http://nadoloni.com'})
	id = str(int(attrs['id']));
	tags.update({'nadoloni:id':"bridges:"+id})
	
	return tags