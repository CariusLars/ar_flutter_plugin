import Foundation
import ARCoreCloudAnchors

// Listener that can be attached to hosing or resolving processes
protocol CloudAnchorListener {
    // Callback to invoke when cloud anchor task finishes
    func onCloudTaskComplete(anchorName: String?, anchor: GARAnchor?)
}

// Class for handling logic regarding the Google Cloud Anchor API
class CloudAnchorHandler: NSObject, GARSessionDelegate {
    private var session: GARSession
    private var pendingAnchors = [GARAnchor: (String?, CloudAnchorListener?)]()
    
    init(session: GARSession){
        self.session = session
    }
    
    func hostCloudAnchor(anchorName: String, anchor: ARAnchor, listener: CloudAnchorListener?) {
        do {
            let newAnchor = try self.session.hostCloudAnchor(anchor)
            // Register listener so it is invoked when the operation finishes
            pendingAnchors[newAnchor] = (anchorName, listener)
        } catch {
            print(error)
        }
    }
    
    func hostCloudAnchorWithTtl(anchorName: String, anchor: ARAnchor, listener: CloudAnchorListener?, ttl: Int) {
        do {
            let newAnchor = try self.session.hostCloudAnchor(anchor, ttlDays: ttl)
            // Register listener so it is invoked when the operation finishes
            pendingAnchors[newAnchor] = (anchorName, listener)
        } catch {
            print(error)
        }
    }
    
    func resolveCloudAnchor(anchorId: String, listener: CloudAnchorListener?) {
        do {
            let newAnchor = try self.session.resolveCloudAnchor(anchorId)
            // Register listener so it is invoked when the operation finishes
            pendingAnchors[newAnchor] = (nil, listener)
        } catch {
            print(error)
        }
        
    }
        
    func session(_ session: GARSession, didHost anchor: GARAnchor) {
        pendingAnchors[anchor]?.1?.onCloudTaskComplete(anchorName: pendingAnchors[anchor]?.0, anchor: anchor)
    }
    
    func session(_ session: GARSession, didFailToHost anchor: GARAnchor) {
        pendingAnchors[anchor]?.1?.onCloudTaskComplete(anchorName: pendingAnchors[anchor]?.0, anchor: anchor)
    }
    
    func session(_ session: GARSession, didResolve anchor: GARAnchor) {
        pendingAnchors[anchor]?.1?.onCloudTaskComplete(anchorName: pendingAnchors[anchor]?.0, anchor: anchor)
    }
    
    func session(_ session: GARSession, didFailToResolve anchor: GARAnchor) {
        pendingAnchors[anchor]?.1?.onCloudTaskComplete(anchorName: pendingAnchors[anchor]?.0, anchor: anchor)
    }
    
    // Remove all listeners
    func clearListeners() {
        pendingAnchors.removeAll()
    }
}
