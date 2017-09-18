//
//  wsJSON.swift
//  jsonParser2
//
//  Created by venta on 3/4/17.
//  Copyright © 2017 admin. All rights reserved.
//

import Foundation


//Convertir de (json) a objeto

infix operator <~

//Infix for mutable objects

func <~ <T:jsonGetter>(lhs: inout T , rhs: Any){
    lhs = wsJson.get(json: rhs)
}

func <~ <T:jsonGetter>(lhs: inout T , rhs: (d: Any, k: String)){
    lhs = wsJson.get(json: rhs.d, key: rhs.k)
}

func <~ <T:ExpressibleByNilLiteral>(lhs: inout Optional<T> , rhs: (d: Any, k: String)){
    var a: Optional<T> = nil
    a = wsJson.get(json: rhs.d, key: rhs.k)
    lhs = a
}

func <~ <T>(lhs: inout T , rhs: (d: Any, k: String)){
    lhs = wsJson.get(json: rhs.d, key: rhs.k)
}

func <~ <T:RandomAccessCollection & MutableCollection>(lhs: inout T , rhs: (d: Any, k: String)) where T._Element:jsonGetter{
    lhs = wsJson.get(json: rhs.d, key: rhs.k)
}

func <~ <T:RandomAccessCollection & MutableCollection>(lhs: inout T , rhs: Any) where T._Element:jsonGetter{
    lhs = wsJson.get(json: rhs)
}

func <~ <T: SetAlgebra & Hashable & Collection & ExpressibleByArrayLiteral> (lhs: inout T , rhs: (d: Any, k: String)) where T.Element : Hashable & jsonGetter{
    
    lhs = wsJson.get(json: rhs.d, key: rhs.k)
    
}


//Infix for Inmubatle Types

func <~ <T:jsonGetter>(lhs: T.Type , rhs: Any)->T{
    let temp: T = wsJson.get(json: rhs)
    return temp
}
func <~ <T:jsonGetter>(lhs: T.Type , rhs: (d: Any, k: String))->T{
    let temp: T = wsJson.get(json: rhs.d, key: rhs.k)
    return temp
}
func <~ <T:ExpressibleByNilLiteral>(lhs: T.Type, rhs: (d: Any, k: String))->T{
    let temp: T = wsJson.get(json: rhs.d, key: rhs.k)
    return temp
}
func <~ <T>(lhs: T.Type , rhs: (d: Any, k: String))->T{
    let temp: T = wsJson.get(json: rhs.d, key: rhs.k)
    return temp
}

func <~ <T:RandomAccessCollection & MutableCollection>(lhs: T.Type , rhs: (d: Any, k: String))->T where T._Element:jsonGetter{
    let temp: T = wsJson.get(json: rhs.d, key: rhs.k)
    return temp
}

func <~ <T:RandomAccessCollection & MutableCollection>(lhs: T.Type , rhs: Any)->T where T._Element:jsonGetter{
    let temp: T = wsJson.get(json: rhs)
    return temp
}

func <~ <T: SetAlgebra & Hashable & Collection & ExpressibleByArrayLiteral> (lhs: T.Type , rhs: (d: Any, k: String))->T where T.Element : Hashable & jsonGetter{
        let temp: T = wsJson.get(json: rhs.d, key: rhs.k)
        return temp
}


//Convertir de objeto a json
prefix operator <~

prefix func <~ (val: Dictionary<String,Any>)-> Dictionary<String,Any>?{
    return wsJson.make(dictionary: val)
}

prefix func <~ (val: jsonNameFilter)-> Dictionary<String,Any>?{
    return wsJson.make(object: val)
}

prefix func <~ <T:Collection>(val: T)-> Array<Any>?{
    return wsJson.make(array: val)
}

prefix func <~ (val: Any)-> Dictionary<String,Any>?{
    return wsJson.make(object: val)
}


/*

func initValue<T>(_ val: inout T){
    if(("" as? T) != nil){
        val = "" as! T
    }
    else if ((0 as? T ) != nil){
        val = -1 as! T
    }else if((Bool() as? T) != nil){
        val = false as! T
    }else if(([:] as? T) != nil){
        val = [:] as! T
    }else if(([] as? T) != nil){
        val = [] as! T
    }
}


func initValue<T>(_ val: T) -> T{
    if("" is T){
        return "" as! T
    }
    else if (0 is T){
        return -1 as! T
    }else if(Bool() is T){
        return false as! T
    }else if([:] is T){
        return [:] as! T
    }else if([] is T){
        return [] as! T
    }else{
        fatalError()
    }
}


func initValue<T:jsonGetter>(_ val: T) -> T
{
    return T.init([:])
}


func initValue<T:jsonGetter>(_ val: inout T)
{
    val = T.init([:])
}

*/

/** Protocol used to identify structs and classes that can recieve json data
 
    ## E.G. ##
    Given the folowing struct
 
    ````
    struct aJob{
        var Empleo = "Cocinero"
        var Ocupacion = "BackEnd"
        var Lenguajes = ["C++","NodeJS","Vue.js","Swift"]
    }
    ````
    You can adapt it to the protocol and make it able to recieve json data this way
    ````
    struct aJob: jsonGetter{
        var Empleo = "Cocinero"
        var Ocupacion = "BackEnd"
        var Lenguajes = ["C++","NodeJS","Vue.js","Swift"]
 
        init(){}
 
        init(_ j: Dictionary<String,Any>){
        self.Empleo = wsJson.get(json:j, key: "Empleo")
        self.Ocupacion = wsJson.get(json:j, key: "Empleo")
        self.Lenguajes = wsJson.get(json:j, key: "Empleo")
        }
    }
    ````

 */
protocol jsonGetter{
    /** - Parameter d: A parameter used for internal purposes, it must be used when constructing the protocol this way
        
        ````
        init(_ j: Dictionary<String,Any>){
            self.Empleo = wsJson.get(json:j, key: "Empleo")
            self.Ocupacion = wsJson.get(json:j, key: "Empleo")
            self.Lenguajes = wsJson.get(json:j, key: "Empleo")
        }
        ````
     */
    
  
    init(_ d: Dictionary<String,Any>)

    
    init()
    
}

protocol jsonNameFilter{
    func jsonFilter(originalName: String) -> String?
}

protocol jsonSingleValueConvertible{
    var value: Any {get}
}

/** **A Singleton Struct** which is capable to: 
 
    - Serializes an object **(Structs or classes)** into a Json **Dictionry<String,Any>**
    - Deserializes a Json **Dictionry<String,Any>** , into an object that adapts to the **jsonGetter** protocol
 */
struct wsJson{
    
    /**
        **An enum** that represent the posible types in a class or struct
        ````
            case array
            case single
            case dictionary
            case enu
            case none
        ````
     */
    enum casos{
        case array, single, dictionary, enu, custom, none
    }
    
    /*/////////////////////////////////////////////
 
        CODE RELATED WITH JSON SERIALIZATION
     
    ///////////////////////////////////////////////
    */
    
    
    /**
        Evaluates an Any parameter and returns an enum of type 'casos', with its type
     
        - Parameter value: **an Any object**
        - Returns: **an Enum** of type 'casos'
    */
    private static func types(value: Any)->casos{
        if(value is Int || value is String || value is Double || value is NSString || value is Bool){
            return .single
        }
        else if (value is jsonNameFilter)
        {
            return .custom
        }
        else if let displayStyle = Mirror(reflecting: value).displayStyle {
            let s = String(describing: displayStyle)
            print(s)
            if s.hasPrefix("collection"){
                return .array
            }
            else if s.hasPrefix("dictionary"){
                return .dictionary
            }
            else if s.hasPrefix("set"){
                return .single
            }
            else if s.hasPrefix("enum")
            {
                return .enu
            }
        }
        return .none
    }
    
    /**
     Makes a Json object taking a raw class, or a raw struct
     
     - Parameter object: **an Any object**, representing a Class or Struct
     - Returns: **an Optional(Dictionary<String,Any>)**
     */
    
    static func make(object: Any) -> Dictionary<String,Any>?{
        var dictionaryToReturn: Dictionary<String,Any> = [:]
        let projectMirror = Mirror(reflecting: object)
        let properties = projectMirror.children
        
        for (k,v) in properties {
            dictionaryToReturn[k!] = fill(key: v)
        }
        return Optional(dictionaryToReturn)
    }
    
    /**
     Makes a Json object taking a Dictionary<String,Any>
     
     - Parameter object: **a Dictionary<String,Any>**
     - Returns: **an Optional(Dictionary<String,Any>)** with all the data of clases and subclases that the previous dictionnary might contain into
     */
    static func make(dictionary: Dictionary<String,Any>) -> Dictionary<String,Any>?
    {
        var dictionaryToReturn: Dictionary<String,Any> = [:]
        
        for (k,v) in dictionary{
            dictionaryToReturn[k] = fill(key: v)
        }
        return dictionaryToReturn
    }
    
    /**
     Makes a Json object taking a collection of single values (Like an array)
     
     - Parameter object: **a Colllection**, of single values
     - Returns: **an Optional(Dictionary<String,Any>)**
     */
    
    static func make<T: Collection>(array: T) -> Array<Any>?
    {
        var arrayToReturn: Array<Any> = []
        
        for (k) in array{
            arrayToReturn.append(fill(key: k))
        }
        return arrayToReturn
    }
    
    /**
     Depending of the found type, chooses how to treat it and return it to the Dictionary that is going to be put
     
     - Parameter key: **The object**, to identify
     - Returns: an **Any object**, destinated to be appended in a Dictionary<String,Any>
     */
    private static func fill(key:Any) -> Any
    {
        switch(types(value: key)){
        case .single:
            return key
        case .enu:
            return (key as! jsonSingleValueConvertible).value
        case .custom:
            return make(object: key as! jsonNameFilter) ?? []
        case .array:
            return make(array: key as! Array<Any>) ?? []
        case .dictionary:
            return make(dictionary: key as! Dictionary<String, Any>) ?? [:]
        case .none:
            return make(object: key) ?? [:]
        default:
            return[]
        }
        
    }
    
    
    /**
     Makes a Json object taking a raw class, or a raw struct
     
     - Parameter object: **an Any object**, representing a Class or Struct
     - Returns: **an Optional(Dictionary<String,Any>)**
     */
    static func make(object: jsonNameFilter) -> Dictionary<String,Any>?{
        var dictionaryToReturn: Dictionary<String,Any> = [:]
        let projectMirror = Mirror(reflecting: object)
        let properties = projectMirror.children
        
        for (k,v) in properties {
            let newK = object.jsonFilter(originalName: k!)
            if newK != nil
            {
                dictionaryToReturn[newK!] = fill(key: v)
            }
        }
        return Optional(dictionaryToReturn)
    }
    
    static func make(object: jsonSingleValueConvertible) -> Any{
        return object.value
    }
    
    /*/////////////////////////////////////////////
     
        CODE RELATED WITH JSON DESERIALIZATION
     
     ///////////////////////////////////////////////
     */
    
    
    enum DesError: Error {
        case deletedCache
    }

    
    
    
    ///Dictionary object with the json that is going to be deserialized
    //private static var shared = wsCacheDictionary<String,Dictionary<String,Any>>()
    
    /**
        Used to register the JSON into the singleton
     
     - Parameter json: The object that is going to be registered
     */
    /*static func register(name: String, json:Dictionary<String,Any>){
        shared.setVal(i: name, k: json)
    }*/
    
    /**
     Used to register the JSON into the singleton
     
     - Parameter json: The object that is going to be registered
     */
   /* static func register(name: String, json:NSDictionary){
        shared.setVal(i: name, k: json as! Dictionary<String,Any>)
    }*/
    
    /**
     **Deserializes** the registered json into a **built in object** that is equal to the lvalue of the '=' operator
     
     - Parameter key: **A String** representing the key of an object within the json
     - Parameter json: Only used for internal purposes, use its default value
     */

    
    /**
     **Deserializes** the registered json into a **user-made object that follows the jsonGetter Protocol** that is equal to the lvalue of the '=' operator
     
     - Parameter key: **A String** representing the key of an object within the json
     - Parameter json: Only used for internal purposes, use its default value
     */
    
    static func get<T:jsonGetter>(json: Any, key: String)->T{
        var dat = json as! Dictionary<String,Any>
        var key = key
        
        self.search(dat: &dat, key: &key)
        
        if(dat.index(forKey: key) == nil)
        {
            return(T([:]))
        }
        
        return ( T(dat[dat.index(forKey: key)!].value as! Dictionary<String, Any>))
    }
    
   /* static func get<T:ExpressibleByNilLiteral & jsonGetter>(json: Any, key: String)->T{
        let dat = json as! Dictionary<String,Any>
        
        guard(dat.index(forKey: key) != nil) else
        {
            return nil
        }
        
        return (T(dat[dat.index(forKey: key)!].value as! Dictionary<String, Any>))
    }*/
    
    private static func search(dat: inout Dictionary<String,Any>, key: inout String){
        if key.contains(".")
        {
            let splitted = key.characters.split(separator: ".")
            let indices = splitted.count - 1
            var currentIndex = 0
            var error: Bool = false
            splitted.forEach({ (characters) in
                
                guard !error else{
                    return
                }
                
                let string = String(characters)
                key = string
                if(dat.index(forKey: string) != nil && currentIndex != indices )
                {
                    dat = dat[dat.index(forKey: string)!].value as! Dictionary<String,Any>
                    currentIndex += 1
                    
                }else
                {
                    
                    error = true
                }
                
            })
        }
        
    }
    
    static func get<T:jsonGetter>(json: Any)->T{
        print(json)
        let dat = json as! Dictionary<String,Any>
        return (T(dat))
    }
    
    static func get<T>(json: Any, key: String)->T{
        var dat = json as! Dictionary<String,Any>
        var key = key
        print(key)
        self.search(dat: &dat, key: &key)
        
        if(dat.index(forKey: key) == nil)
        {
            print("El campo \"\(key)\" no fue encontrado")
            if(("" as? T) != nil){
                return "" as! T
            }
            else if ((0 as? T ) != nil){
                return 0 as! T
            }else if((Double() as? T) != nil){
                return 0.0 as! T
            }else if((Bool() as? T) != nil){
                return false as! T
            }else if(([:] as? T) != nil){
                return [:] as! T
            }else if ([] as? T) != nil{
                return [] as! T
            }
            
        }
        
        if (dat[dat.index(forKey: key)!].value) is T{
            return (dat[dat.index(forKey: key)!].value) as! T
        }else{
            print("El campo \"\(key)\" no se puedo castear)")
            if(("" as? T) != nil){
                return "" as! T
            }
            else if ((0 as? T ) != nil){
                return 0 as! T
            }else if((0.0 as? T) != nil){
                return 0.0 as! T
            }else if((Bool() as? T) != nil){
                return false as! T
            }else if(([:] as? T) != nil){
                return [:] as! T
            }else if ([] as? T) != nil{
                return [] as! T
            }
        }
        return (dat[dat.index(forKey: key)!].value) as! T
    }
    
//    static func get<T:ExpressibleByNilLiteral>(json: Any, key: String)->T?{
//        var dat = json as! Dictionary<String,Any>
//        var key = key
//        print(key)
//        self.search(dat: &dat, key: &key)
//        
//        if(dat.index(forKey: key) == nil)
//        {
//            print("El campo \"\(key)\" no fue encontrado")
//            return nil
//            
//        }
//        return (dat[dat.index(forKey: key)!].value) as? T
//    }
    
    static func get<T: SetAlgebra & Hashable & Collection & ExpressibleByArrayLiteral> (json: Any, key: String) -> T where T.Element : Hashable & jsonGetter{
    
        var dat = json as! Dictionary<String,Any>
        var key = key
        
        if(dat.index(forKey: key) == nil)
        {
            print("El campo \"\(key)\" no fue encontrado")
            if(("" as? T) != nil){
                return "" as! T
            }
            else if ((0 as? T ) != nil){
                return 0 as! T
            }else if((Bool() as? T) != nil){
                return false as! T
            }else if(([:] as? T) != nil){
                return [:] as! T
            }
            
        }


        var set: T = []
        var k = dat.index(forKey: key)
        
        if k != nil{
            var elements: [T.Element] = wsJson.get(json: dat[k!].value)
            for element in elements{
                set.insert(element)
            }
        }
        
        return set
    }

    
    
    
   static func gett<T:ExpressibleByNilLiteral>(json: Any, key: String)->T{
        var dat = json as! Dictionary<String,Any>
        var key = key
    
    
    
        self.search(dat: &dat, key: &key)

    
        guard(dat.index(forKey: key) != nil) else
        {
            return nil
        }
    
    if (dat[dat.index(forKey: key)!].value) is T{
        return (dat[dat.index(forKey: key)!].value) as! T
    }else{
        return nil
    }
    

    
    }
    
    static func get<T:RandomAccessCollection & MutableCollection>(json: Any)->T where T._Element:jsonGetter{
        let j = json as! [Any]
        var k : [T._Element] = []
        for element in j{
           k.append(T._Element(element as! Dictionary<String,Any>))
        }
        return (k) as! T
    }

    
    static func get<T:RandomAccessCollection & MutableCollection>(json: Any, key: String)->T where T._Element:jsonGetter{
        
        var dat = json as! Dictionary<String,Any>
        var key = key
        
        self.search(dat: &dat, key: &key)
        
        if(dat.index(forKey: key) == nil)
        {
            if(([] as? T) != nil){
                return [] as! T
            }else if(([:] as? T) != nil){
                return [:] as! T
            }
        }
        
        let j = (dat[dat.index(forKey: key)!].value) as! [Any]

        var k : [T._Element] = []
        for element in j{
            k.append(T._Element(element as! Dictionary<String,Any>))
        }
        return (k) as! T
    }
    
    static func get<T:RandomAccessCollection & MutableCollection>(son: Any, key: String)->T where T._Element:jsonGetter{
        
        var dat = son as! Dictionary<String,Any>
        var key = key
        
        self.search(dat: &dat, key: &key)
        
        if(dat.index(forKey: key) == nil)
        {
            if(([] as? T) != nil){
                return [] as! T
            }else if(([:] as? T) != nil){
                return [:] as! T
            }
        }
        
        let j = (dat[dat.index(forKey: key)!].value) as! [Any]
        
        var k : [T._Element] = []
        for element in j{
            k.append(T._Element(element as! Dictionary<String,Any>))
        }
        return (k) as! T
    }
    
    
    


    
    
//////////////////
//////////////////
//////////////////
//////////////////
//////////////////

    /*
    
    /**
     **Deserializes** the registered json into a **built in object** that is equal to the lvalue of the '=' operator
     
     - Parameter key: **A String** representing the key of an object within the json
     - Parameter json: Only used for internal purposes, use its default value
     */
    static func get<T>(json jsonString: String, key: String)throws ->T{
        
        guard((shared[jsonString]) != nil) else {
            throw DesError.deletedCache
        }
        
        let json = shared[jsonString]!
        
        precondition(json.index(forKey: key) != nil, "////////////////////////////////\n////////////////////////////////\nThe key identified as '\(key)', doesnt exist in the following dictionary: \n\(json)\n////////////////////////////////\n////////////////////////////////\n ")
        return (json[json.index(forKey: key)!].value) as! T
    }
    
    /**
     **Deserializes** the registered json into a **user-made object that follows the jsonGetter Protocol** that is equal to the lvalue of the '=' operator
     
     - Parameter key: **A String** representing the key of an object within the json
     - Parameter json: Only used for internal purposes, use its default value
     */
    static func get<T:jsonGetter>(json jsonString: String, key: String)throws ->T{
        
        guard((shared[jsonString]) != nil) else {
            throw DesError.deletedCache
        }
        
        let json = shared[jsonString]!
        
        precondition(json.index(forKey: key) != nil, "////////////////////////////////\n////////////////////////////////\nThe key identified as '\(key)', doesnt exist in the following dictionary: \n\(json)\n////////////////////////////////\n////////////////////////////////\n ")
        return (T(json[json.index(forKey: key)!].value as! Dictionary<String, Any>))
    }
 
 
 
 */
    
}
