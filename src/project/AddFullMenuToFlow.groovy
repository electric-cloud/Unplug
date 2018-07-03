/*

Electric Flow DSL - Create a procedure that adds all Unplug views to Flow UI
- Creates a new /server/ec_ui/flowMenuExtension if it doesn't already exist
- Adds or replaces Unplug menu tree
- Uses the key from /server/unplug/v<key> for part of the menu name
- Uses the description from this property if not the default or uses unplug property v_example<key>

The typical resulting menu property will be:

<?xml version="1.0" encoding="UTF-8"?>
<menu>
	<tab>
		<label>DSL IDE</label>
		<url>plugins/EC-DSLIDE-1.4.10/index.html</url>
	</tab>
	<tab>
		<label>Unplug</label>
		<tab>
			<label>A description</label>
			<url>plugins/unplug/un_run0</url>
		</tab>
		<!-- etc -->
	</tab>
</menu>

*/

def PluginName = args.pluginName

project PluginName,{
	procedure "Remove Unplug from Flow Menu",{
		step "Remove", shell: 'ectool evalDsl --dslFile "{0}"', command: '''\
			import groovy.xml.*
			def InitialMenuXML = getProperties(path: "/server/ec_ui").property.find { it.name == "flowMenuExtension" }?.value?:"<menu/>"

			def InitialMenu = new XmlParser().parseText(InitialMenuXML)
			def nodeToDel=InitialMenu.tab.find { it.label.text() == 'Unplug' }
			def parent = nodeToDel.parent()
			parent.remove(nodeToDel)
			property "/server/ec_ui/flowMenuExtension", value: groovy.xml.XmlUtil.serialize( InitialMenu )		
		'''.stripIndent()
	} // procedure
	procedure "Add Unplug to Flow Menu",{
		step "Add", shell: 'ectool evalDsl --dslFile "{0}"', command: """\
			import groovy.xml.*

			def UnplugProperties = [:]
			getProperties(path: "/server/unplug").property.each { prop ->
				def uprop = (prop.name =~ /^v([0-9a-z])/)
				if (uprop) {
					def index = uprop[0][1]
					if (prop.description.startsWith("Content to be displayed")) {
						// Use Unplug example description
						UnplugProperties[index] = getProperty(propertyName:"/projects/${PluginName}/v_example\${index}", expand: false).description
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

			// TODO: make sure it exists
			//getProperties(path: "/server/ec_ui").property.each { if (it.name = "flowMenuExtension") return it.value}
			//def InitialMenuXML = getProperty("/server/ec_ui/flowMenuExtension").value
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
} // project