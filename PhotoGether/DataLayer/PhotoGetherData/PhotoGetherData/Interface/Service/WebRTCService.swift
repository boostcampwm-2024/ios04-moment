import Foundation
import Combine
import WebRTC

public protocol WebRTCService: RTCPeerConnectionDelegate, RTCDataChannelDelegate {    
    var didGenerateLocalCandidatePublisher: AnyPublisher<RTCIceCandidate, Never> { get }
    var didChangeConnectionStatePublisher: AnyPublisher<RTCIceConnectionState, Never> { get }
    var didReceiveDataPublisher: AnyPublisher<Data, Never> { get }
    
    var peerConnection: RTCPeerConnection { get }
    
    // MARK: SDP
    func offer() async throws -> RTCSessionDescription
    func answer() async throws -> RTCSessionDescription
    func set(remoteSdp: RTCSessionDescription) async throws
    func set(localSdp: RTCSessionDescription) async throws
    func set(remoteCandidate: RTCIceCandidate) async throws
    
    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void)
    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void)
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void)
    func set(localSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void)
    func set(remoteCandidate: RTCIceCandidate, completion: @escaping (Error?) -> Void)
    
    // MARK: Video
    func renderLocalVideo(to renderer: RTCVideoRenderer)
    func renderRemoteVideo(to renderer: RTCVideoRenderer)
    func connectVideoTrack(videoTrack: RTCVideoTrack)

    // MARK: Data
    func sendData(_ data: Data)
    func connectDataChannel(dataChannel: RTCDataChannel?)
    
    // MARK: Audio
    func muteAudio()
    func unmuteAudio()
    func connectAudioTrack(audioTrack: RTCAudioTrack)
}
