//
//  ContentView.swift
//  Graph
//
//  Created by Patrick Maltagliati on 10/16/20.
//

import SwiftUI
import CoreData

/*
 MARK0:
 实时获取 View 的 Size
 https://juejin.cn/post/7285604041933602831
 
 MARK1:
 解决 ScrollView 无法缩放的问题
 https://stackoverflow.com/questions/62884288/how-can-i-zoom-into-a-scrollview-in-swiftui
 
 
 MARK2：
 解决 ScrollView 缩放过程中 scale 不同步的问题
 https://stackoverflow.com/questions/58341820/isnt-there-an-easy-way-to-pinch-to-zoom-in-an-image-in-swiftui
 */


// MARK0
struct SizeCalculator: ViewModifier {
    @Binding var size: CGSize
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    let geoSize = proxy.size
                    Color.clear
                        .onAppear {
                            size = geoSize
                        }
                        .onChange(of: geoSize) { newValue in
                            size = geoSize
                        }
                }
            )
    }
}

extension View {
    func readSize(in size: Binding<CGSize>) -> some View {
        modifier(SizeCalculator(size: size))
    }
}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var lastScaleValue: CGFloat = 1.0
    @State var scale = 1.0
    @State var size: CGSize = .zero
    
    @FetchRequest(
        entity: Node.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "isRoot == YES"),
        animation: .default
    )
    private var nodes: FetchedResults<Node>
    
    var body: some View {
        NavigationView {
            if let root = nodes.first {
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    TreeView(root: root, viewContext: viewContext)
                        .readSize(in: $size)
                        // MARK1
                        .scaleEffect(self.scale)
                        .frame(width: self.size.width * self.scale, height:  self.size.height * self.scale)
                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
                .gesture(
                    MagnificationGesture()
                        // MARK2
                        .onChanged({ val in
                            let delta = val / self.lastScaleValue
                            self.lastScaleValue = val
                            let newScale = self.scale * delta
                            self.scale = newScale
                            print("onChanged", val)
                        })
                        .onEnded { val in
                            print("onEnded", val)
                            self.lastScaleValue = 1.0
                        }
                )
                .navigationBarItems(
                    leading: Button(action: restart) { Label("Restart", systemImage: "restart.circle") }
                )
            } else {
                VStack {
                    Button(
                        action: newRoot,
                        label: {
                            Label("New", systemImage: "plus")
                        }
                    )
                }
                .navigationBarItems(leading: EmptyView(), trailing: EmptyView())
            }
        }
    }
    
    private func newRoot() {
        let root = Node(context: viewContext)
        root.id = UUID()
        root.name = "Root"
        root.isRoot = true
        try? viewContext.save()
    }
    
    private func restart() {
        let request = NSBatchDeleteRequest(fetchRequest: Node.fetchRequest())
        request.resultType = .resultTypeObjectIDs
        guard
            let result = try? viewContext.execute(request),
            let deleteResult = result as? NSBatchDeleteResult,
            let ids = deleteResult.result as? [NSManagedObjectID]
        else { return }
        let changes = [NSDeletedObjectsKey: ids]
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: changes,
            into: [viewContext]
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
