import UIKit

import BaseFeature
import DesignSystem
import PhotoGetherDomainInterface

protocol StickerViewActionDelegate: AnyObject {
    func stickerView(_ stickerView: StickerView, didTap id: UUID)
    func stickerView(_ stickerView: StickerView, didTapDelete id: UUID)
    func stickerView(_ stickerView: StickerView, willBeginDraging sticker: StickerEntity)
    func stickerView(_ stickerView: StickerView, didDrag sticker: StickerEntity)
    func stickerView(_ stickerView: StickerView, didEndDrag sticker: StickerEntity)
    func stickerView(_ stickerView: StickerView, willBeginResizing sticker: StickerEntity)
    func stickerView(_ stickerView: StickerView, didResize sticker: StickerEntity)
    func stickerView(_ stickerView: StickerView, didEndResize sticker: StickerEntity)
}

final class StickerView: UIView {
    private let nicknameLabel = PTGPaddingLabel()
    private let imageView = UIImageView()
    private let layerView = UIView()
    private let deleteButton = UIButton()
    private let resizeButton = UIButton()
    private let dragPanGestureRecognizer = UIPanGestureRecognizer()
    private let resizePanGestureRecognizer = UIPanGestureRecognizer()

    private var sticker: StickerEntity
    private let user: UserInfo?

    weak var delegate: StickerViewActionDelegate?
    
    init(
        sticker: StickerEntity,
        user: UserInfo?
    ) {
        self.sticker = sticker
        self.user = user
        super.init(frame: sticker.frame)
        setupGesture()
        setupTarget()
        addViews()
        setupConstraints()
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addViews() {
        [imageView, nicknameLabel, layerView, deleteButton, resizeButton].forEach {
            addSubview($0)
        }
    }
    
    private func setupConstraints() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(6)
        }
        
        nicknameLabel.snp.makeConstraints {
            $0.top.equalTo(snp.bottom)
            $0.centerX.equalTo(imageView)
        }
        
        layerView.snp.makeConstraints {
            $0.edges.equalTo(imageView)
        }
        
        deleteButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        resizeButton.snp.makeConstraints {
            $0.bottom.trailing.equalToSuperview()
            $0.width.height.equalTo(20)
        }
    }
    
    private func configureUI() {
        isExclusiveTouch = true
        
        let deleteButtonImage = PTGImage.xmarkIcon.image
        layerView.layer.borderWidth = 2
        layerView.layer.borderColor = PTGColor.primaryGreen.color.cgColor
        layerView.isUserInteractionEnabled = false
        
        deleteButton.setImage(deleteButtonImage, for: .normal)
        deleteButton.layer.cornerRadius = deleteButton.bounds.width / 2
        deleteButton.clipsToBounds = true
        deleteButton.isExclusiveTouch = true
        
        let resizeButtonImage = PTGImage.resizeIcon.image
        resizeButton.setImage(resizeButtonImage, for: .normal)
        resizeButton.layer.cornerRadius = resizeButton.bounds.width / 2
        resizeButton.clipsToBounds = true
        resizeButton.isExclusiveTouch = true
        
        setImage(to: sticker.image)
        updateOwnerUI(owner: sticker.owner)
        updateDeleteButtonVisibility(for: sticker.owner)
        updateResizeButtonVisibility(for: sticker.owner)
    }
    
    private func setupGesture() {
        isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        dragPanGestureRecognizer.minimumNumberOfTouches = 1
        dragPanGestureRecognizer.addTarget(self, action: #selector(handleDragPanGesture))
        addGestureRecognizer(dragPanGestureRecognizer)
        
        resizePanGestureRecognizer.minimumNumberOfTouches = 1
        resizePanGestureRecognizer.addTarget(self, action: #selector(handleResizePanGesture))
        resizeButton.addGestureRecognizer(resizePanGestureRecognizer)
    }
    
    @objc private func handleDragPanGesture(_ gesture: UIPanGestureRecognizer) {
        let initialPoint = sticker.frame.origin
        let translationPoint = gesture.translation(in: self)
        let changedX = initialPoint.x + translationPoint.x
        let changedY = initialPoint.y + translationPoint.y
        let traslationStickerPoint = CGPoint(x: changedX, y: changedY)
        
        dragPanGestureRecognizer.setTranslation(.zero, in: self)
        
        let newFrame = CGRect(origin: traslationStickerPoint, size: sticker.frame.size)
        
        switch gesture.state {
        case .began:
            updateFrame(to: newFrame)
            updateOwner(to: user)
            delegate?.stickerView(self, willBeginDraging: sticker)
        case .changed:
            updateFrame(to: newFrame)
            delegate?.stickerView(self, didDrag: sticker)
        case .ended:
            delegate?.stickerView(self, didEndDrag: sticker)
        default: break
        }
    }
    
    @objc private func handleResizePanGesture(_ gesture: UIPanGestureRecognizer) {
        let initialSize = sticker.frame.size
        let translationPoint = gesture.translation(in: self)
        let delta = min(translationPoint.x, translationPoint.y)
        let changedWidth = min(128, max(initialSize.width + delta, 48))
        let changedHeight = changedWidth
        let traslationStickerSize = CGSize(width: changedWidth, height: changedHeight)
        
        resizePanGestureRecognizer.setTranslation(.zero, in: resizeButton)
        let newFrame = CGRect(origin: sticker.frame.origin, size: traslationStickerSize)
        
        switch gesture.state {
        case .began:
            updateFrame(to: newFrame)
            delegate?.stickerView(self, willBeginResizing: sticker)
        case .changed:
            updateFrame(to: newFrame)
            delegate?.stickerView(self, didResize: sticker)
        case .ended:
            delegate?.stickerView(self, didEndResize: sticker)
        default: break
        }
    }
    
    private func setupTarget() {
        deleteButton.addTarget(
            self,
            action: #selector(deleteButtonTapped),
            for: .touchUpInside
        )
    }
    
    private func updateFrame(to frame: CGRect) {
        guard sticker.frame != frame else { return }
        
        sticker.updateFrame(to: frame)
        self.frame = frame
    }
    
    private func updateOwner(to owner: UserInfo?) {
        guard sticker.owner != owner else { return }
        
        sticker.updateOwner(to: owner)
        updateOwnerUI(owner: owner)
        updateDeleteButtonVisibility(for: owner)
        updateResizeButtonVisibility(for: owner)
        updatePanGestureState()
    }
    
    private func updateOwnerUI(owner: UserInfo?) {
        if let owner = owner {
            nicknameLabel.text = owner.nickname
            layerView.isHidden = false
            nicknameLabel.isHidden = false
        } else {
            nicknameLabel.text = nil
            layerView.isHidden = true
            nicknameLabel.isHidden = true
        }
        
        if owner == user {
            layerView.layer.borderColor = PTGColor.primaryGreen.color.cgColor
            nicknameLabel.backgroundColor = PTGColor.primaryGreen.color
        } else {
            guard let hexColor = owner?.viewPosition.color.rawValue else { return }
            layerView.layer.borderColor = UIColor(hex: hexColor).cgColor
            nicknameLabel.backgroundColor = UIColor(hex: hexColor)
        }
    }

    private func updateDeleteButtonVisibility(for owner: UserInfo?) {
        let isOwner = owner == user
        deleteButton.isHidden = !isOwner
        deleteButton.isUserInteractionEnabled = isOwner
    }
    
    private func updateResizeButtonVisibility(for owner: UserInfo?) {
        let isOwner = owner == user
        resizeButton.isHidden = !isOwner
        resizeButton.isUserInteractionEnabled = isOwner
    }
    
    private func updatePanGestureState() {
        if sticker.owner == user || sticker.owner == nil {
            dragPanGestureRecognizer.isEnabled = true
        } else {
            dragPanGestureRecognizer.isEnabled = false
        }
    }
    
    private func setImage(to urlString: String) {
        guard let url = URL(string: urlString) else { return }

        Task { await imageView.setAsyncImage(url) }
    }
    
    @objc private func handleTap() {
        delegate?.stickerView(self, didTap: sticker.id)
    }
    
    @objc private func deleteButtonTapped() {
        delegate?.stickerView(self, didTapDelete: sticker.id)
    }
    
    func update(with sticker: StickerEntity) {
        switch dragPanGestureRecognizer.state {
        case .began, .changed:
            return
        default:
            updateOwner(to: sticker.owner)
            
            if sticker.owner != user {
                updateFrame(to: sticker.frame)
            }
        }
    }
    
    func prepareSharePhoto() {
        guard sticker.owner != nil else { return }

        updateOwnerUI(owner: nil)
        updateDeleteButtonVisibility(for: nil)
        updateResizeButtonVisibility(for: nil)
    }
    
    func finishSharePhoto() {
        guard sticker.owner != nil else { return }
        
        updateOwnerUI(owner: sticker.owner)
        updateDeleteButtonVisibility(for: sticker.owner)
        updateResizeButtonVisibility(for: sticker.owner)
    }
}
