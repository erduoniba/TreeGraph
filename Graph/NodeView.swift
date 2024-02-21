//
//  NodeView.swift
//  Graph
//
//  Created by Patrick Maltagliati on 10/17/20.
//

import SwiftUI
import CoreData

/*
 MARK1
 移除字符串第一个字符
 https://www.jianshu.com/p/9e5056bc79ca
 */

struct NodeView: View {
    @ObservedObject var node: Node
    let viewContext: NSManagedObjectContext
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 60, height: 60, alignment: .center)
            Text("\(node.name ?? "No name")").foregroundColor(.white).padding()
        }
        .onTapGesture(count: 2) {
            if node.isRoot == true {
                let child = Node(context: viewContext)
                child.id = UUID()
                child.name = "R\(Int.random(in: 1...9))"
                node.isRoot = false
                // MARK1
                if let startIndex = node.name?.startIndex {
                    node.name?.remove(at: startIndex)
                }
                child.isRoot = true
                child.addToChildren(node)
                try? viewContext.save()
            }
        }
        .onTapGesture {
            withAnimation {
                let child = Node(context: viewContext)
                child.id = UUID()
                child.name = "\(Int.random(in: 1...9))"
                child.parent = node
                try? viewContext.save()
            }
        }
        
        
        .contextMenu(ContextMenu(menuItems: {
            Button(action: {
                viewContext.delete(node)
                try? viewContext.save()
            }, label: {
                Label("Delete", systemImage: "trash")
            })
        }))
    }
}

struct NodeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let node = Node(context: context)
        node.name = "Pat"
        return NodeView(node: node, viewContext: context)
    }
}
