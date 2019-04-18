var Action = function() {}

Action.prototype = {
    
run: function(parameters) {
    parameters.completionFunction({"URL": document.URL, "title": document.title }); // tell iOS that JS has finished its preprocessing and give back this dictionary
},
    
finalize: function(parameters) {
    var customJavaScript = parameters["customJavaScript"];
    eval(customJavaScript);
}
    
};

var ExtensionPreprocessingJS = new Action
