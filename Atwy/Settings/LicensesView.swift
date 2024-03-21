//
//  LicensesView.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 29.07.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import SwiftUI

public struct LicensesView: View {
    private let licenses: [LicenseView.License] = [
        .init(
            name: "InfiniteScrollViews",
            content: """
                MIT License
            
                Copyright (c) 2023 Antoine Bollengier
            
                Permission is hereby granted, free of charge, to any person obtaining a copy
                of this software and associated documentation files (the "Software"), to deal
                in the Software without restriction, including without limitation the rights
                to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                copies of the Software, and to permit persons to whom the Software is
                furnished to do so, subject to the following conditions:
            
                The above copyright notice and this permission notice shall be included in all
                copies or substantial portions of the Software.
            
                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                SOFTWARE.
            """,
            isSelf: true,
            link: URL(string: "https://github.com/b5i/InfiniteScrollViews")!
        ),
        .init(
            name: "YouTubeKit",
            content: """
                Copyright 2023-2024 Antoine Bollengier

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
            """,
            isSelf: true,
            link: URL(string: "https://github.com/b5i/YouTubeKit")!
        ),
        .init(
            name: "CachedAsyncImage",
            content: """
                MIT License
            
                Copyright (c) 2021 Lorenzo Fiamingo
            
                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
            
                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
            
                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
            """,
            isSelf: false,
            link: URL(string: "https://github.com/lorenzofiamingo/swiftui-cached-async-image")!
        ),
        .init(
            name: "SwipeActions",
            comment: "Andrew = the 🐐",
            content: """
                    MIT License
                
                    Copyright (c) 2023 A. Zheng
                
                    Permission is hereby granted, free of charge, to any person obtaining a copy
                    of this software and associated documentation files (the "Software"), to deal
                    in the Software without restriction, including without limitation the rights
                    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                    copies of the Software, and to permit persons to whom the Software is
                    furnished to do so, subject to the following conditions:
                
                    The above copyright notice and this permission notice shall be included in all
                    copies or substantial portions of the Software.
                
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                    SOFTWARE.
            """,
            isSelf: false,
            link: URL(string: "https://github.com/aheze/SwipeActions")!
        )
    ]
    
    public var body: some View {
        VStack {
            List {
                ForEach(Array(licenses.enumerated()), id: \.offset) { _, license in
                    Group {
                        Text(license.name)
                        Text(license.comment)
                            .foregroundColor(.gray)
                            .bold()
                            .font(.system(size: 10))
                            .frame(alignment: .trailing)
                        Spacer()
                        if license.isSelf {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50)
                                    .foregroundStyle(.red)
                                    .frame(width: 80, height: 20)
                                Text("Homemade")
                                    .bold()
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .routeTo(.licence(license: license))
                }
            }
        }
        .navigationTitle("Licenses")
    }
}
