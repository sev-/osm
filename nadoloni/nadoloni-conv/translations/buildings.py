# -*- coding: utf-8 -*-
"""
Translation rules for VMap0 populated areas translation project done by GIS-Lab.info
http://gis-lab.info/qa/vmap0-settl-rus.html
"""

def translateAttributes(attrs):
	if not attrs: return
	
	tags = {}
	
	if attrs['title_ua']:
		tags = {'addr:housenumber':attrs['title_ua']}

	tags.update({'building':'yes'})
	tags.update({'source':'nadoloni.com import'})
	tags.update({'source_ref':'http://nadoloni.com'})
	id = str(int(float(attrs['nadoloni_i'])))
	print "id:" + attrs['osm_id'] + " OR "
	tags.update({'nadoloni:id':"buildings:"+id})
	
	return tags
