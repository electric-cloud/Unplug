procedure "Add Unplug to Flow Menu",{
	step "Add", shell: 'ectool evalDsl --dslFile "{0}"', command: """\
		import groovy.xml.*

		def UnplugProperties = [:]
		getProperties(path: "/server/unplug").property.each { prop ->
			def uprop = (prop.name =~ /^v([0-9a-z])/)
			if (uprop) {
				def index = uprop[0][1]
				if (prop.description.startsWith("Content to be displayed")) {
					// Use plugin example description
					def PluginDescription = getProperty(propertyName:"/projects/${PluginName}/v_example\${index}", expand: false)?.description
					if (PluginDescription == null || PluginDescription == "An empty page.") {
						// No content, so don't add menu item
					} else {
						UnplugProperties[index] = PluginDescription
					}
				} else {
					// Use /server/unplug/vX description
					UnplugProperties[index] = prop.description
				}
			}
		}

		// Build Unplug menu
		def UnplugMenu = new NodeBuilder()
		def UnplugTab = UnplugMenu.tab {
			label("Unplug")
			UnplugProperties.each { k,v ->
				tab {
					label (k + " - " + v)
					url ("pages/unplug/un_run\${k}")
				}
			}
		}

		// Make sure flowMenuExtension property exists
		def InitialMenuXML = getProperties(path: "/server/ec_ui").property.find { it.name == "flowMenuExtension" }?.value?:"<menu/>"

		def InitialMenu = new XmlParser().parseText(InitialMenuXML)
		def Nodes=[]
		// TODO: only push <label> values
		InitialMenu.tab.each {Nodes.push(it.label.text())}
		if (!("Unplug" in Nodes)) {
			InitialMenu.append(UnplugTab)
		} else {
			def nodeToDel=InitialMenu.tab.find { it.label.text() == 'Unplug' }
			def parent = nodeToDel.parent()
			parent.remove(nodeToDel)
			InitialMenu.append(UnplugTab)
		}
		property "/server/ec_ui/flowMenuExtension", value: groovy.xml.XmlUtil.serialize( InitialMenu )
	""".stripIndent()
} // procedure
