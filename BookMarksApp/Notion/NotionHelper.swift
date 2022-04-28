//
//  NotionHelper.swift
//  BookMarksApp
//
//  Created by sunil on 20/03/22.
//

import Foundation
import NotionSwift

protocol Notionable: class {
    func didReceived(pages: [NotionPage])
    func didUpdatedNewLink(tag: Tag, links: [NotionLink])
}

struct NotionLink {
    let uuid: String
    let url: String
}

struct NotionPage {
    let uuid: String
    let title: String
    var links: [NotionLink]?
    
    mutating func updateLinks(_ links: [NotionLink] ) {
        self.links = links
    }
}

class NotionHelper {
    let notion = NotionClient(accessKeyProvider: StringAccessKeyProvider(accessKey: "secret_VAzaEpCK2wp6FrQnJZiXbwt8l7qVmrz9RfDUenlziq1"))
    
    weak var delegate: Notionable?
    
    static let sharedInstance = NotionHelper()
    
    var notionPages = [NotionPage]() {
        didSet {
            self.delegate?.didReceived(pages: notionPages)
        }
    }
    
    private init() {
    }
    
    func getNotionPages(){
        notion.search(request: .init(filter: .page)) { result in
            switch result {
            case .success(let searchResult):
                let pages = self.pages(list: searchResult)
                var newPages = [NotionPage]()
                for page in pages {
                    self.getUrlsOfPage(page)
                    newPages.append(NotionPage.init(uuid: page.uuid, title: page.title, links: nil))
                }
                self.notionPages = pages
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func getUrlsOfPage(_ page: NotionPage) {
        self.notion.page(pageId: Page.Identifier(page.uuid)) { result in
            print(result)
            switch result {
            case .success(let page):
                self.notion.blockChildren(blockId: page.id.toBlockIdentifier) { result in
                    switch result {
                    case .success(let list):
                        self.getBlocksOfPage(pageId: page.id.rawValue, list)
                    case .failure(let error):
                        print("error \(error)")
                    }
                }
            default:
                break
            }
        }
    }
    
    func deleteAPage() {
        
        
    }
    
    func getBlocksOfPage(pageId: String, _ list: ListResponse<NotionSwift.ReadBlock>) -> [NotionLink]{
        var notionLinks = [NotionLink]()
        
        for block in list.results {
            
            switch block.type {
            case .bookmark(let value):
                if let _ = URL.init(string: value.url) {
                    notionLinks.append(NotionLink.init(uuid: block.id.rawValue, url: value.url))
                }
                
                print(value.url)
            case .embed(let value):
                print(value.url)
                if let _ = URL.init(string: value.url) {
                    notionLinks.append(NotionLink.init(uuid: block.id.rawValue, url: value.url))
                }
            default:
                print("\n")
            }
        }
        
        var notionPages = self.notionPages.filter { $0.uuid == pageId }
        
        guard let index = self.notionPages.firstIndex(where: {$0.uuid == pageId}) else {
            return notionLinks
        }
        
        if var notionPage = notionPages.first {
            notionPage.updateLinks(notionLinks)
            self.notionPages[index].updateLinks(notionLinks)
        }
        
        return notionLinks
        
    }
    
    func pages(list : ListResponse<SearchResultItem>) -> [NotionPage] {
        var pages = [NotionPage]()
        for pageResult in list.results {
            switch pageResult {
            case .page(let page):
                print("Page ID => \(page.id)")
                if let titleProperty = page.getTitle() {
                    for richText in titleProperty {
                        if let plainText = richText.plainText {
                            print("Page Title => \(plainText)")
                            pages.append(NotionPage.init(uuid: page.id.rawValue, title: plainText, links: nil))
                        }
                    }
                }
            case .database(let database):
                print("database")
            case .unknown:
                print("unknown")
            }
        }
        return pages
    }
    
    func addNotionLink(url: String, tag: Tag){
        let blocks: [WriteBlock] = [WriteBlock.init(type: .embed(url: url, caption: []))]
        
        notion.blockAppend(blockId: Block.Identifier(tag.uuid!), children: blocks) { result in
            switch result {
            case .success(let listResponse):
                print("")
                let notionPages = self.getBlocksOfPage(pageId: tag.uuid!, listResponse)
                self.delegate?.didUpdatedNewLink(tag: tag, links: notionPages)
            case .failure(let error):
                print("failure")
            }
        
        }
    }
    
    func createAPage(){
        let parentPageId = Page.Identifier(UUID().uuidString)
        let request = PageCreateRequest(
            parent: .page(parentPageId),
            properties: [
                "title": .init(
                    type: .title([
                        .init(string: "Test Sunil")
                    ])
                )
            ]
        )
        notion.pageCreate(request: request) {
            print($0)
        }
    }

}
