Before Slatwall runs you need to add the following to your application file.

this.mappings["/Slatwall"] = "#getDirectoryFromPath(expandPath('/'))#Slatwall";
arrayAppend(this.ormsettings.cfclocation, "/Slatwall/model/entity");