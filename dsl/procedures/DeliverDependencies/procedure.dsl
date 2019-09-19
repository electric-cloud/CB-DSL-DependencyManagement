// This procedure.dsl was generated automatically
// DO NOT EDIT THIS BLOCK === procedure_autogen starts ===
procedure 'DeliverDependencies', description: 'This procedure delivers dependencies to the agent/ folder of the plugin on the agent machine', {

    step 'DeliverDependencies', {
        description = ''
        command = new File(pluginDir, "dsl/procedures/DeliverDependencies/steps/DeliverDependencies.pl").text
        shell = 'ec-perl'

        postProcessor = '''$[/myProject/perl/postpLoader]'''
    }
// DO NOT EDIT THIS BLOCK === procedure_autogen ends, checksum: b4a0f25430550015133f0762cfe9c669 ===
// Do not update the code above the line
// procedure properties declaration can be placed in here, like
// property 'property name', value: "value"
}