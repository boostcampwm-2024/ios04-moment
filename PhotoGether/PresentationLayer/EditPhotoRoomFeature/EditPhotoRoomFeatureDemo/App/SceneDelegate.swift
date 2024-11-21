import UIKit
import EditPhotoRoomFeature
import PhotoGetherData
import PhotoGetherDomainInterface
import PhotoGetherDomain
import PhotoGetherDomainTesting
import PhotoGetherNetwork
import DesignSystem

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let urlString = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? ""
        let url = URL(string: urlString)!
        debugPrint("SignalingServer URL: \(url)")
        
        let webScoketClient: WebSocketClient = WebSocketClientImpl(url: url)
        let signalingService: SignalingService = SignalingServiceImpl(webSocketClient: webScoketClient)
        
        let webRTCService: WebRTCService = WebRTCServiceImpl(iceServers: [
            "stun:stun.l.google.com:19302",
            "stun:stun1.l.google.com:19302",
            "stun:stun2.l.google.com:19302",
            "stun:stun3.l.google.com:19302",
            "stun:stun4.l.google.com:19302"
        ])
        let connectionClient: ConnectionClient = ConnectionClientImpl(
            signalingService: signalingService,
            webRTCService: webRTCService
        )
        let localDataSource = LocalShapeDataSourceImpl()
        let remoteDataSource = RemoteShapeDataSourceImpl()
        let shapeRepositoryImpl = ShapeRepositoryImpl(
            localDataSource: localDataSource,
            remoteDataSource: remoteDataSource
        )
        let fetchEmojiListUseCase = FetchEmojiListUseCaseImpl(
            shapeRepository: shapeRepositoryImpl
        )
        let images = [
            PTGImage.temp1.image,
            PTGImage.temp2.image,
            PTGImage.temp3.image,
            PTGImage.temp4.image,
        ]
        let frameImageGenerator = FrameImageGeneratorImpl(images: images)
        let editPhotoRoomGuestViewModel = EditPhotoRoomHostViewModel(
            fetchEmojiListUseCase: fetchEmojiListUseCase,
            frameImageGenerator: frameImageGenerator
        )
        let editPhotoRoomGuestViewController = EditPhotoRoomHostViewController(
            viewModel: editPhotoRoomGuestViewModel
        )
        window?.rootViewController = editPhotoRoomGuestViewController
        window?.makeKeyAndVisible()
    }
}
