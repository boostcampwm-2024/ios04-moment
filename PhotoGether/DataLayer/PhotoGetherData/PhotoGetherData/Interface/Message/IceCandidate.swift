import Foundation
import WebRTC

public struct IceCandidate: Codable {
    public let sdp: String
    public let sdpMLineIndex: Int32
    public let sdpMid: String?
    public let userID: String // MARK: Offer를 보내는 사람의 ID
    public let roomID: String // MARK: 참가하려는 방의 ID
    
    public init(from iceCandidate: RTCIceCandidate, userID: String, roomID: String) {
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
        self.sdp = iceCandidate.sdp
        self.userID = userID
        self.roomID = roomID
    }
    
    public var rtcIceCandidate: RTCIceCandidate {
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: self.sdpMid)
    }
}
