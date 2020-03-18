//
//  JKNodeModel.swift
//  TreeTableView
//
//  Created by Prashant on 15/03/20.
//  Copyright © 2020 Prashant. All rights reserved.
//

import Foundation

class JKNodeModel:NSObject,NSCoding {

    var hasChildrenRegion: String!
    var parentID: String!
    var childrenID: String!
    var name: String?
    var isExpand: Bool = false
    var level: Int?
    var isLeaf: Bool = false
    var isRoot: Bool = false
    var isSelected: Bool = false
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
    }
    
    required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObject(forKey: "name") as? String
    }
    
    convenience init(parentID:String, name:String, childrenID:String, hasChildrenRegion:String) {
        self.init(parentID: parentID, name: name, childrenID: childrenID, level: nil, hasChildrenRegion: hasChildrenRegion)
    }
    
    init (parentID:String, name:String, childrenID:String, level:Int?, hasChildrenRegion:String) {
        self.parentID = parentID
        self.name = name
        self.childrenID = childrenID
        self.level = level
        self.hasChildrenRegion = hasChildrenRegion
        
        //Project characteristics can be judged directly
        self.isRoot = parentID == "-1" ? true : false
        self.isLeaf = hasChildrenRegion == "0" ? true : false
    }
    
    override var description: String {
        return "parentID:\(String(describing: parentID)) childrenID:\(String(describing: childrenID)) name:\(String(describing: name)) level:\(String(describing: level)) isExpand:\(isExpand)"
    }
}
// MARK: - NSObject Has complied with the Equatable protocol
extension JKNodeModel {
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? JKNodeModel else { return false }
        return self.parentID == other.parentID && self.childrenID == other.childrenID && self.name == other.name
    }
}
