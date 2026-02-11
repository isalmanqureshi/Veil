//
//  ChatView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct ChatView: View {
    
    let username: String
    @StateObject private var vm: ChatViewModel
    
    init(username: String, repo: ChatRepository) {
        self.username = username
        _vm = StateObject(wrappedValue: ChatViewModel(chatUsername: username, repo: repo))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.messages) { m in
                            MessageBubble(message: m)
                                .id(m.id)
                                .onTapGesture {
                                    if m.state == .failed {
                                        vm.retryFailed(m)
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                .onChange(of: vm.messages.count) { _, _ in
                    if let last = vm.messages.last?.id {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
            
            // Composer
            HStack(spacing: 10) {
                TextField("Message", text: $vm.draftText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                
                Button {
                    vm.showTimerSelector = true
                } label: {
                    Image(systemName: "timer")
                }
                .accessibilityLabel("Message timer")
                .sheet(isPresented: $vm.showTimerSelector) {
                    MessageTimerSelectorView(
                        selectedTimer: $vm.selectedTimer,
                        makeDefault: $vm.makeDefaultForChat
                    )
                }
                
                Button {
                    // Attachment flow (mock hook)
                } label: {
                    Image(systemName: "paperclip")
                }
                .accessibilityLabel("Attachment")
                
                Button {
                    vm.sendTapped()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!vm.canSend)
                .opacity(vm.canSend ? 1 : 0.4)
                .accessibilityLabel("Send")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Image(systemName: "shield.fill")
                Button { } label: { Image(systemName: "lock") }
            }
        }
        .onAppear {
            // Replace placeholder repo with app env repo if you have it wired
            // If your AppEnvironment already has chatRepo, inject it here:
            // vm = ChatViewModel(chatUsername: username, repo: env.chatRepo)
        }
    }
}



#Preview {
    ChatView(username: "usernmae", repo: MockChatRepository(crypto: MockCryptoService()))
}
