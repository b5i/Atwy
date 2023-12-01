//
//  SettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 26.11.22.
//

import SwiftUI
import Security
import AVKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var APIM = APIKeyModel.shared
    @State private var showingConfirmation: Bool = false
    @State private var showInstructions: Bool = true
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    UserPreferenceCircleView()
                        .frame(width: 100, height: 100)
                        .padding(.top)
                    if let account = APIM.userAccount, account.name != nil {
                        VStack {
                            Text(account.name ?? "")
                                .font(.title2)
                                .bold()
                            Text(account.channelHandle ?? "")
                                .font(.footnote)
                                .bold()
                                .foregroundColor(.gray)

                            HStack {
                                Text("Unlink account")
                                Image(systemName: "minus.circle")
                                    .frame(width: 30, height: 30)
                            }
                            .foregroundColor(.red)
                            .onTapGesture {
                                showingConfirmation = true
                            }
                            .confirmationDialog("Unlink account?", isPresented: $showingConfirmation) {
                                Button("Yes", role: .destructive) {
                                    APIM.deleteAccount()
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("Unlink confirmation")
                            }
                            .padding(.vertical)
                        }
                    } else {
                        VStack {
                            NavigationLink(destination: {
                                GoogleConnectionView()
                            }, label: {
                                HStack {
                                    Text("Connect your YouTube account")
                                    Image(systemName: "plus.circle")
                                        .frame(width: 30, height: 30)
                                }
                            })
                        }
                    }
                    List {
                        NavigationLink(destination: {
                            AppearanceSettingsView()
                        }, label: {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .foregroundColor(.blue)
                                    Image(systemName: "textformat.size")
                                        .foregroundColor(.white)
                                }
                                .frame(width: 30, height: 30)
                            }
                            Text("Appeareance")
                            Spacer()
                        })
                        NavigationLink(destination: {
                            StorageSettingsView()
                        }, label: {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .foregroundColor(.gray)
                                    Image(systemName: "gear")
                                        .foregroundColor(.white)
                                }
                                .frame(width: 30, height: 30)
                            }
                            Text("Storage")
                            Spacer()
                        })
                        NavigationLink(destination: {
                            LicensesView()
                        }, label: {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .foregroundColor(.orange)
                                    Image(systemName: "book.fill")
                                        .foregroundColor(.white)
                                }
                                .frame(width: 30, height: 30)
                            }
                            Text("Licenses")
                            Spacer()
                        })
                    }
                    .frame(height: 200)
                }
            }
            .navigationTitle("Account")
            #if os(macOS)
            .toolbar(content: {
                ToolbarItem(placement: .secondaryAction, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                            .bold()
                    }
                })
            })
            #else
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                            .bold()
                    }
                })
            })
            #endif
        }
    }
}
