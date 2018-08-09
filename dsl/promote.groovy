import groovy.transform.BaseScript
import com.electriccloud.commander.dsl.util.BasePlugin

//noinspection GroovyUnusedAssignment
@BaseScript BasePlugin baseScript

// Variables available for use in DSL code
def pluginName = args.pluginName
def upgradeAction = args.upgradeAction
def otherPluginName = args.otherPluginName

def pluginKey = getProject("/plugins/$pluginName/project").pluginKey
def pluginDir = getProperty("/projects/$pluginName/pluginDir").value

//List of procedure steps to which the plugin configuration credentials need to be attached
// ** steps with attached credentials
def stepsWithAttachedCredentials = [
		/*[
			procedureName: 'Procedure Name',
			stepName: 'step that needs the credentials to be attached'
		 ],*/
	]
// ** end steps with attached credentials

project pluginName, {

	loadPluginProperties(pluginDir, pluginName)
	// Workaround for lack of property support in pluginwizard, PEFF-18
	property "v_example0", description: "An empty page."
	property "v_example1", description: "Text"
	property "v_example2", description: "HTML"
	property "v_example3", description: "Property expansion"
	property "v_example4", description: "Perl"
	property "v_example5", description: "Perl jobs"
	property "v_example6", description: "Embedded javascript"
	property "v_example7", description: "Custom Parameter"
	property "v_example8", description: "Flot Charting"
	property "v_example9", description: "An empty page."
	property "v_examplea", description: "DSL"
 

 
	
	loadProcedures(pluginDir, pluginKey, pluginName, stepsWithAttachedCredentials)
	
	
	
	
	//plugin configuration metadata
	property 'ec_config', {
		form = '$[' + "/projects/${pluginName}/procedures/CreateConfiguration/ec_parameterForm]"
		property 'fields', {
			property 'desc', {
				property 'label', value: 'Description'
				property 'order', value: '1'
			}
		}
	}

}

// Copy existing plugin configurations from the previous
// version to this version. At the same time, also attach
// the credentials to the required plugin procedure steps.
upgrade(upgradeAction, pluginName, otherPluginName, stepsWithAttachedCredentials)

/*
transaction {
	runProcedure projectName: pluginName, procedureName "Add Unplug to Commander Menu.groovy"
	runProcedure projectName: pluginName, procedureName "Add Unplug to Flow Menu.groovy"
}
*/
