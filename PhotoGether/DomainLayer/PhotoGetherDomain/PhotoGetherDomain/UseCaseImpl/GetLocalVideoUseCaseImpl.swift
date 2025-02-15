import Foundation
import UIKit
import PhotoGetherDomainInterface

public final class GetLocalVideoUseCaseImpl: GetLocalVideoUseCase {
    public func execute() -> (UserInfo?, UIView) {
        return (connectionRepository.localUserInfo, connectionRepository.localVideoView)
    }
    
    private let connectionRepository: ConnectionRepository
    
    public init(connectionRepository: ConnectionRepository) {
        self.connectionRepository = connectionRepository
    }
}
