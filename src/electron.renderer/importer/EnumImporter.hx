package importer;

class EnumImporter {
    public static function load(path:String, isSync:Bool) {
        var extension=dn.FilePath.extractExtension(path);
        switch(extension)
        {
            case "hx":
                importer.HxEnum.load(path, isSync);
                
            case "csv":
                importer.CsvEnum.load(path, isSync);

                // Todo Add Castle db file extension here
        }
    }
}