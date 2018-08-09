procedure "Remove Unplug from Commander Menu",{
	step "Remove", shell: 'ectool evalDsl --dslFile "{0}"', command: '''\
		import groovy.xml.*
		def InitialMenuXML = getProperties(path: "/server/ec_ui/availableViews").property.find { it.name == "Default" }?.value?:"<menu/>"

		def InitialMenu = new XmlParser().parseText(InitialMenuXML)
		def nodeToDel=InitialMenu.tab.find { it.label.text() == 'Unplug' }
		def parent = nodeToDel.parent()
		parent.remove(nodeToDel)
		property "/server/ec_ui/availableViews/Default", value: groovy.xml.XmlUtil.serialize( InitialMenu )		
	'''.stripIndent()
} // procedure