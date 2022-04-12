//
//  Created by Wojciech Chojnacki on 02/06/2021.
//

import Foundation

public struct Environment {
    static var log = Logger(handler: EmptyLogHandler(), level: .info)
    public static var logHandler: LoggerHandler {
        get { log.handler }
        set { log.handler = newValue }
    }

    public static var logLevel: LogLevel {
        get { log.level }
        set { log.level = newValue }
    }
}
