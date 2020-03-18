//
//  ViewController.swift
//  TreeTableView
//
//  Created by Prashant on 14/03/20.
//  Copyright © 2020 Prashant. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var myTable: UITableView!
    var preservation: Bool = false
    var rootID: String!
    /// Raw node data
    var nodes: [JKNodeModel]!
    /// Node data currently displayed
    var tempNodes = [JKNodeModel]()
    ///Need to be inserted or deleted RowIndex
    var reloadArray: [IndexPath]?
    var selectBlock:((JKNodeModel) -> Void)?
    var selectedRegionBlock: ((JKNodeModel)->Void)?

    var selectedNodeID:String?
    static let cellHeight:CGFloat = 45.0

    override func viewDidLoad() {
        super.viewDidLoad()
        myTable.delegate = self
        myTable.dataSource = self
        myTable.register(UINib.init(nibName: "JKMultiLevelCell", bundle: nil), forCellReuseIdentifier: "JKMultiLevelCell")
        initUI()
    }
    
    func initUI(){
        let fakeNodes = fakeData()
        initMytable(nodes: fakeNodes, rootID: nil, selectBlock: { (selectedNode) in
            print("Select node" + (selectedNode.name ?? "name is nil"))
            if self.selectedRegionBlock != nil {
                self.selectedRegionBlock!(selectedNode)
                if fakeNodes.contains(selectedNode) {
                    print("selected node contained in fakeNodes")
                } else {
                    print("selected node not contained!")
                }
                
                let equalNodesArr = fakeNodes.filter({ (node) -> Bool in
                    node == selectedNode
                })
                for (i,node) in equalNodesArr.enumerated() {
                    print("equalNodesArr \(i) \(node.description)")
                }
            }
            
            //FIXME: test local save
            do {
                //let encodeData = try NSKeyedArchiver.archivedData(withRootObject: selectedNode, requiringSecureCoding: false)
                let encodeData = try NSKeyedArchiver.archivedData(withRootObject: selectedNode)
                UserDefaults.standard.set(encodeData, forKey: "TEST_ARCHIVE")
            } catch let error {
                print("archived error:\(error)")
            }
        })
    }
    func initMytable(nodes:[JKNodeModel], rootID:String?, selectBlock:((JKNodeModel) -> Void)?) {
        self.rootID = rootID ?? "-1"
        self.selectBlock = selectBlock
        self.preservation = false
        configNodes(nodes: nodes)
    }
    
    // MARK: - Nodes Config
    func configNodes(nodes:[JKNodeModel]) {
        self.nodes = nodes
        updateNodesLevel()
        addFirstLoadNodes()
        myTable.reloadData()
    }
    
    func updateNodesLevel() {
        setDepthWithParentIdAndChildrenNodes(nodeLevel: 1, parentIDs: [rootID], childrenNodes: nodes)
    }
    
    func setDepthWithParentIdAndChildrenNodes(nodeLevel:Int, parentIDs:[String], childrenNodes:[JKNodeModel]) {
        var newParentIDs = [String]()
        var leftNodes = childrenNodes
        
        for node in childrenNodes {
            if parentIDs.contains(node.parentID) {
                node.level = nodeLevel
                leftNodes = leftNodes.filter({ (leftNode) -> Bool in
                    leftNode.childrenID != node.childrenID
                })
                newParentIDs.append(node.childrenID)
            }
        }
        
        if leftNodes.count > 0 {
            let nextLevel = nodeLevel + 1
            setDepthWithParentIdAndChildrenNodes(nodeLevel: nextLevel, parentIDs: newParentIDs, childrenNodes: leftNodes)
        }
    }
    
    func addFirstLoadNodes() {
        for node in nodes {
            if node.isRoot == true {
                tempNodes.append(node)
            }
        }
        reloadArray = [IndexPath]()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tempNodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JKMultiLevelCell") as! JKMultiLevelCell
        cell.node(node: tempNodes[indexPath.row])
        cell.cellIndicatorBlock = {[weak self] node in
            if self?.selectBlock != nil {
                self?.selectBlock!(node)
            }
            self?.updateSelectedNode(nodeID: node.childrenID)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = tempNodes[indexPath.row] as JKNodeModel
        
        if node.isLeaf {
            //1.LeafNode Handle click events
            if selectBlock != nil {
                selectBlock!(node)
            }
            updateSelectedNode(nodeID: node.childrenID)
            return
        } else {
            node.isExpand = !node.isExpand
        }
        
        //Refresh once cell
        tableView.reloadRows(at: [indexPath], with: .none)
        reloadArray?.removeAll()
        if node.isExpand {
            expandNodesFor(parentID: node.childrenID!, insertIndex: indexPath.row)
            tableView.insertRows(at: reloadArray!, with: .none)
        } else {
            //3.Collapse node
            foldNodesFor(level: node.level!, currentIndex: indexPath.row)
            tableView.deleteRows(at: reloadArray!, with: .none)
        }
        
    }
    
    func updateSelectedNode(nodeID:String) {
        selectedNodeID = nodeID
        nodes.forEach { (node) in
            if node.childrenID != selectedNodeID {
                node.isSelected = false
            } else {
                node.isSelected = true
            }
        }
       myTable.reloadData()
    }
    func fakeData() -> [JKNodeModel] {
        
        let list = [["parentID":"-1", "name":"Node1", "ID":"1", "hasChildrenRegion":"1"],
                    ["parentID":"1", "name":"Node10", "ID":"10", "hasChildrenRegion":"1"],
                    ["parentID":"1", "name":"Node11", "ID":"11", "hasChildrenRegion":"1"],
                    ["parentID":"10", "name":"Node100", "ID":"100", "hasChildrenRegion":"0"],
                    ["parentID":"10", "name":"Node101", "ID":"101", "hasChildrenRegion":"0"],
                    ["parentID":"11", "name":"Node110", "ID":"110", "hasChildrenRegion":"0"],
                    ["parentID":"11", "name":"Node111", "ID":"111", "hasChildrenRegion":"0"]
                   ]
  
        
        var array = [JKNodeModel]()
        for dic in list {
            if let pID = dic["parentID"],let name = dic["name"],let id = dic["ID"],let hasChild = dic["hasChildrenRegion"] {
                let node = JKNodeModel.init(parentID: pID, name: name, childrenID: id, hasChildrenRegion: hasChild)
                array.append(node)
            }
        }
        return array as [JKNodeModel]
    }
    
    // MARK: - Cells Expand or Fold
    func expandNodesFor(parentID:String, insertIndex: Int) -> Void {
        var theInsertIndex = insertIndex
        for node in nodes {
            if node.parentID == parentID {
                node.isExpand = false
                theInsertIndex = theInsertIndex + 1
                tempNodes.insert(node, at: theInsertIndex)
                reloadArray?.append(IndexPath.init(row: theInsertIndex, section: 0))
            }
        }
    }
    
    func foldNodesFor(level:Int, currentIndex:Int) -> Void {
        if currentIndex + 1 < tempNodes.count {
            let copyTempNodes = tempNodes
            
            for i in stride(from: currentIndex + 1, to: tempNodes.count, by: 1) {
                if copyTempNodes[i].level! <= copyTempNodes[currentIndex].level! {
                    break
                } else {
                    tempNodes = tempNodes.filter({ (node) -> Bool in
                        node.childrenID != copyTempNodes[i].childrenID
                    })
                    reloadArray?.append(IndexPath.init(row: i, section: 0))
                }
            }
        }
    }
    
    
}

