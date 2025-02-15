import Foundation
import Combine
import PhotoGetherNetwork
import PhotoGetherDomainInterface
import CoreModule

public final class RoomServiceImpl: RoomService {
    public var createRoomResponsePublisher: AnyPublisher<RoomOwnerEntity, Error> {
        _createRoomResponsePublisher.eraseToAnyPublisher()
    }
    public var joinRoomResponsePublisher: AnyPublisher<JoinRoomEntity, Error> {
        _joinRoomResponsePublisher.eraseToAnyPublisher()
    }
    public var notifyRoomResponsePublisher: AnyPublisher<NotifyNewUserEntity, Error> {
        _notifyRoomReponsePublisher.eraseToAnyPublisher()
    }
    private let _createRoomResponsePublisher = PassthroughSubject<RoomOwnerEntity, Error>()
    private let _joinRoomResponsePublisher = PassthroughSubject<JoinRoomEntity, Error>()
    private let _notifyRoomReponsePublisher = PassthroughSubject<NotifyNewUserEntity, Error>()
    private var cancellables: Set<AnyCancellable> = []
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private var webSocketClient: WebSocketClient
    
    public init(webSocketClient: WebSocketClient) {
        self.webSocketClient = webSocketClient
        bindWebSocketClient()
    }
    
    public func createRoom() -> AnyPublisher<RoomOwnerEntity, Error> {
        let createRoomRequest = RoomRequestDTO(messageType: .createRoom)
        
        guard let data = createRoomRequest.toData(encoder: encoder) else {
            PTGLogger.default.log("방 생성 요청 데이터 인코딩 실패: \(createRoomRequest)")
            return Fail(error: RoomServiceError.failedToEncoding).eraseToAnyPublisher()
        }
        
        webSocketClient.send(data: data)
        return createRoomResponsePublisher
    }
    
    public func joinRoom(to roomID: String) -> AnyPublisher<JoinRoomEntity, Error> {
        let joinRoomMessage = JoinRoomRequestMessage(roomID: roomID).toData(encoder: encoder)
        let joinRoomRequest = RoomRequestDTO(messageType: .joinRoom, message: joinRoomMessage)
        
        guard let data = joinRoomRequest.toData(encoder: encoder) else {
            PTGLogger.default.log("방 참가 요청 데이터 인코딩 실패: \(joinRoomRequest)")
            return Fail(error: RoomServiceError.failedToEncoding).eraseToAnyPublisher()
        }
        
        webSocketClient.send(data: data)
        return joinRoomResponsePublisher
    }
    
    private func bindWebSocketClient() {
        self.webSocketClient.webSocketdidReceiveDataPublisher
            .sink { [weak self] data in
                guard let self else { return }
                
                guard let response = data.toDTO(type: RoomResponseDTO.self, decoder: decoder) else { return }
                
                switch response.messageType {
                case .createRoom:
                    guard let message = response.message else { return }
                    guard let message = message.toDTO(
                        type: CreateRoomResponseMessage.self,
                        decoder: decoder
                    ) else {
                        PTGLogger.default.log("Decode Failed to CreateRoomMessage: \(message)")
                        return
                    }
                    let roomOwnerEntity = message.toEntity()
                    _createRoomResponsePublisher.send(roomOwnerEntity)
                    
                    PTGLogger.default.log("방 생성 성공: \(message.roomID) \n 유저 아이디: \(message.hostID)")
                case .joinRoom:
                    guard let message = decodeMessage(
                        response.message,
                        type: JoinRoomResponseMessage.self
                    ) else {
                        PTGLogger.default.log("Decode Failed to JoinRoomEntity: \(String(describing: response.message))")
                        return
                    }
                    let joinRoomEntity = message.toEntity()
                    _joinRoomResponsePublisher.send(joinRoomEntity)
                    
                    PTGLogger.default.log("방 참가 성공\n 유저 아이디: \(message.userID) \n 방 유저목록: \(message.userList)")
                case .notifyNewUser:
                    guard let message = decodeMessage(
                        response.message,
                        type: NotifyNewUserMessage.self
                    ) else {
                        PTGLogger.default.log("Decode Failed to JoinRoomEntity: \(String(describing: response.message))")
                        return
                    }
                    let notifyNewUserEntity = message.toEntity()
                    _notifyRoomReponsePublisher.send(notifyNewUserEntity)
                }
            }.store(in: &cancellables)
    }
    
    private func decodeMessage<T: Decodable>(_ message: Data?, type: T.Type) -> T? {
        guard let message = message else { return nil }
        guard let dto = message.toDTO(type: type, decoder: decoder) else {
            PTGLogger.default.log("Decode Failed to: \(message)")
            return nil
        }
        
        return dto
    }
}

public enum RoomServiceError: LocalizedError {
    case failedToEncoding
    
    public var errorDescription: String? {
        switch self {
        case .failedToEncoding:
            return "Failed to encode room service request"
        }
    }
}
