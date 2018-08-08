//dsl
def projects = getProjects()
def writer = new StringWriter()  // html is written here by markup builder
def markup = new groovy.xml.MarkupBuilder(writer)  // the builder
markup.html {
  table (border: "1px solid black") {
    tr {
      th("Name")
      th("Creation Date")
    }
    projects.each { proj ->
      if (!proj.pluginName){
        tr {
          td(proj.name)
          td(proj.createTime)
        }
      }
    }
  }
}
writer.toString()