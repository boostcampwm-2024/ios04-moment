import UIKit
import Combine
import PhotoGetherDomainInterface

public final class PhotoRoomViewModel {
    private var cancellables = Set<AnyCancellable>()
    private var timerCount: Int = 3
    
    enum Input {
        case cameraButtonTapped
        case micButtonTapped
    }
    
    enum Output {
        case timer(count: Int)
        case timerCompleted(images: [UIImage], userInfo: UserInfo?)
        case micMuteState(Bool)
    }
    
    private var output = PassthroughSubject<Output, Never>()
    private var userInfo: UserInfo?
    private let captureVideosUseCase: CaptureVideosUseCase
    private let stopVideoCaptureUseCase: StopVideoCaptureUseCase
    private let getUserInfoUseCase: GetLocalVideoUseCase
    private let changeLocalMicStateUseCase: ChangeLocalMicStateUseCase
    
    public init(
        captureVideosUseCase: CaptureVideosUseCase,
        stopVideoCaptureUseCase: StopVideoCaptureUseCase,
        getUserInfoUseCase: GetLocalVideoUseCase,
        changeLocalMicStateUseCase: ChangeLocalMicStateUseCase
    ) {
        self.captureVideosUseCase = captureVideosUseCase
        self.stopVideoCaptureUseCase = stopVideoCaptureUseCase
        self.getUserInfoUseCase = getUserInfoUseCase
        self.changeLocalMicStateUseCase = changeLocalMicStateUseCase
    }
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] in
            guard let self else { return }
            
            switch $0 {
            case .cameraButtonTapped:
                self.startTimer()
            case .micButtonTapped:
                self.handleMicButtonDidTap()
            }
        }.store(in: &cancellables)
        
        return output.eraseToAnyPublisher()
    }
    
    private func startTimer() {
        guard let userInfo = getUserInfoUseCase.execute().0 else { return }
        self.userInfo = userInfo
        
        output.send(.timer(count: timerCount))
        
        let _ = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] timer in
            guard let self else { return }
            
            self.timerCount -= 1
            self.output.send(.timer(count: self.timerCount))
            
            if self.timerCount == 0 {
                self.timerCount = 3
                
                let images = self.captureVideosUseCase.execute()
                let result = Output.timerCompleted(images: images, userInfo: userInfo)
                self.stopVideoCaptureUseCase.execute()
                
                self.output.send(result)
                timer.invalidate()
            }
        }
    }
    
    private func handleMicButtonDidTap() {
        changeLocalMicStateUseCase.execute()
            .sink { [weak self] state in
                self?.output.send(.micMuteState(state))
            }.store(in: &cancellables)
    }
}
