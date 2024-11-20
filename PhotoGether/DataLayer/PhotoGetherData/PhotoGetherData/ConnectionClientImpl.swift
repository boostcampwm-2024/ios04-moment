import Foundation
import WebRTC
import Combine
import PhotoGetherDomainInterface

public final class ConnectionClientImpl: ConnectionClient {
    private let signalingClient: SignalingService
    private let webRTCClient: WebRTCClient
    
    public var receivedDataPublisher = PassthroughSubject<Data, Never>()
    
    public var remoteVideoView: UIView = RTCMTLVideoView()
    public var localVideoView: UIView = RTCMTLVideoView()
    
    public var peerID: String = ""
    public var roomID: String = ""
    
    public init(signalingClient: SignalingService, webRTCClient: WebRTCClient) {
        self.signalingClient = signalingClient
        self.webRTCClient = webRTCClient
        
        self.signalingClient.delegate = self
        self.webRTCClient.delegate = self
        
        // 서버 자동 연결
        self.connect()
        
        // VideoTrack과 나와 상대방의 화면을 볼 수 있는 뷰를 바인딩합니다.
        self.bindRemoteVideo()
        self.bindLocalVideo()
    }
    
    public func sendOffer() {
        self.webRTCClient.offer { sdp in
            self.signalingClient.send(sdp: sdp, peerID: self.peerID, roomID: self.roomID)
        }
    }
    
    public func sendData(data: Data) {
        self.webRTCClient.sendData(data)
    }
    
    private func connect() {
        self.signalingClient.connect()
    }
    
    /// remoteVideoTrack과 상대방의 화면을 볼 수 있는 뷰를 바인딩합니다.
    private func bindRemoteVideo() {
        guard let remoteVideoView = remoteVideoView as? RTCMTLVideoView else { return }
        self.webRTCClient.renderRemoteVideo(to: remoteVideoView)
    }
    
    private func bindLocalVideo() {
        guard let localVideoView = localVideoView as? RTCMTLVideoView else { return }
        self.webRTCClient.startCaptureLocalVideo(renderer: localVideoView)
    }
}

// MARK: SignalingClientDelegate
extension ConnectionClientImpl: SignalingClientDelegate {
    public func signalClientDidConnect(
        _ signalingClient: SignalingService
    ) {
        // TODO: 서버 연결 완료 로직 처리
    }
    
    public func signalClientDidDisconnect(
        _ signalingClient: SignalingService
    ) {
        // TODO: 서버 연결 끊김 로직 처리
    }
    
    public func signalClient(
        _ signalingClient: SignalingService,
        didReceiveRemoteSdp sdp: RTCSessionDescription
    ) {
        guard self.webRTCClient.peerConnection.remoteDescription == nil else { return }
        
        // TODO: 컴플리션 핸들러 -> async로 리팩토링
        self.webRTCClient.set(remoteSdp: sdp) { error in
            if let error { debugPrint(error) }
            
            guard self.webRTCClient.peerConnection.localDescription == nil else { return }
            
            self.webRTCClient.answer { sdp in
                self.signalingClient.send(sdp: sdp, peerID: self.peerID, roomID: self.roomID)
            }
        }
    }
    
    public func signalClient(
        _ signalingClient: SignalingService,
        didReceiveCandidate candidate: RTCIceCandidate
    ) {
        self.webRTCClient.set(remoteCandidate: candidate) { _ in }
    }
}

// MARK: WebRTCClientDelegate
extension ConnectionClientImpl: WebRTCClientDelegate {
    /// SDP 가 생성되면 LocalCandidate 가 생성되기 시작 (가능한 경로만큼 생성됨)
    public func webRTCClient(
        _ client: WebRTCClient,
        didGenerateLocalCandidate candidate: RTCIceCandidate
    ) {
        self.signalingClient.send(candidate: candidate, peerID: self.peerID, roomID: self.roomID)
    }
    
    public func webRTCClient(
        _ client: WebRTCClient,
        didChangeConnectionState state: RTCIceConnectionState
    ) {
        // TODO: 피어커넥션 연결 상태 변경에 따른 처리
    }

    /// peerConnection의 remoteDataChannel 에 데이터가 수신되면 호출됨
    public func webRTCClient(
        _ client: WebRTCClient,
        didReceiveData data: Data
    ) {
        receivedDataPublisher.send(data)
    }
}
