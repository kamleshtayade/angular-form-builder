###
    component:
        It is like a class.
        The base components are textInput, textArea, select, check, radio.
        User can custom the form with components.
    formObject:
        It is like an object (an instance of the component).
        User can custom the label, description, required and validation of the input.
    form:
        This is for end-user. There are form groups int the form.
        They can input the value to the form.
###

a = angular.module 'builder.provider', []

a.provider '$builder', ->
    # ----------------------------------------
    # properties
    # ----------------------------------------
    @version = '0.0.1'
    # all components
    @components = {}
    # all groups of components
    @groups = []
    @broadcastChannel =
        updateInput: '$updateInput'

    # forms
    #   builder mode: `fb-builder` you could drag and drop to build the form.
    #   form mode: `fb-form` this is the form for end-user to input value.
    @forms =
        default: []
    @formsId =
        default: 0


    # ----------------------------------------
    # private functions
    # ----------------------------------------
    @convertComponent = (name, component) ->
        result =
            name: name
            group: component.group ? 'Default'
            label: component.label ? ''
            description: component.description ? ''
            placeholder: component.placeholder ? ''
            editable: component.editable ? yes
            required: component.required ? no
            validation: component.validation ? '/.*/'
            validationOptions: component.validationOptions ? []
            options: component.options ? []
            arrayToText: component.arrayToText ? no
            template: component.template
            popoverTemplate: component.popoverTemplate
        if not result.template then console.error "The template is empty."
        if not result.popoverTemplate then console.error "The popoverTemplate is empty."
        result

    @convertFormObject = (name, formObject={}) ->
        component = @components[formObject.component]
        throw "The component #{formObject.component} was not registered." if not component?
        if formObject.id
            exist = no
            for form in @forms[name] when formObject.id <= form.id # less and equal
                formObject.id = @formsId[name]++
                exist = yes
                break
            @formsId[name] = formObject.id + 1 if not exist
        result =
            id: formObject.id ? @formsId[name]++
            component: formObject.component
            editable: formObject.editable ? component.editable
            index: formObject.index ? 0
            label: formObject.label ? component.label
            description: formObject.description ? component.description
            placeholder: formObject.placeholder ? component.placeholder
            options: formObject.options ? component.options
            required: formObject.required ? component.required
            validation: formObject.validation ? component.validation
        result

    @reindexFormObject = (name) =>
        formObjects = @forms[name]
        for index in [0...formObjects.length] by 1
            formObjects[index].index = index
        return

    # ----------------------------------------
    # public functions
    # ----------------------------------------
    @registerComponent = (name, component={}) =>
        ###
        Register the component for form-builder.
        @param name: The component name.
        @param component: The component object.
            group: {string} The component group.
            label: {string} The label of the input.
            description: {string} The description of the input.
            placeholder: {string} The placeholder of the input.
            editable: {bool} Is the form object editable?
            required: {bool} Is the form object required?
            validation: {string} angular-validator. "/regex/" or "[rule1, rule2]". (default is RegExp(.*))
            validationOptions: {array} [{rule: angular-validator, label: 'option label'}] the options for the validation. (default is [])
            options: {array} The input options.
            arrayToText: {bool} checkbox could use this to convert input (default is no)
            template: {string} html template
            popoverTemplate: {string} html template
        ###
        if not @components[name]?
            # regist the new component
            newComponent = @convertComponent name, component
            @components[name] = newComponent
            if newComponent.group not in @groups
                @groups.push newComponent.group
        else
            console.error "The component #{name} was registered."
        return

    @addFormObject = (name, formObject={}) =>
        ###
        Insert the form object into the form at last.
        ###
        @forms[name] ?= []
        @insertFormObject name, @forms[name].length, formObject

    @insertFormObject = (name, index, formObject={}) =>
        ###
        Insert the form object into the form at {index}.
        @param name: The form name.
        @param index: The form object index.
        @param form: The form object.
            component: {string} The component name
            editable: {bool} Is the form object editable? (default is yes)
            label: {string} The form object label.
            description: {string} The form object description.
            placeholder: {string} The form object placeholder.
            options: {array} The form object options.
            required: {bool} Is the form object required? (default is no)
            validation: {string} angular-validator. "/regex/" or "[rule1, rule2]".
            [id]: {int} The form object id. It will be generate by $builder.
            [index]: {int} The form object index. It will be updated by $builder.
        ###
        @forms[name] ?= []
        @formsId[name] ?= 0
        if index > @forms[name].length then index = @forms[name].length
        else if index < 0 then index = 0
        @forms[name].splice index, 0, @convertFormObject(name, formObject)
        @reindexFormObject name

    @removeFormObject = (name, index) =>
        ###
        Remove the form object by the index.
        @param name: The form name.
        @param index: The form object index.
        ###
        formObjects = @forms[name]
        formObjects.splice index, 1
        @reindexFormObject name

    @updateFormObjectIndex = (name, oldIndex, newIndex) =>
        ###
        Update the index of the form object.
        @param name: The form name.
        @param oldIndex: The old index.
        @param newIndex: The new index.
        ###
        return if oldIndex is newIndex
        formObjects = @forms[name]
        formObject = formObjects.splice(oldIndex, 1)[0]
        formObjects.splice newIndex, 0, formObject
        @reindexFormObject name

    # ----------------------------------------
    # $get
    # ----------------------------------------
    @get = ->
        version: @version
        components: @components
        groups: @groups
        forms: @forms
        broadcastChannel: @broadcastChannel
        registerComponent: @registerComponent
        addFormObject: @addFormObject
        insertFormObject: @insertFormObject
        removeFormObject: @removeFormObject
        updateFormObjectIndex: @updateFormObjectIndex
    @$get = @get
    return
