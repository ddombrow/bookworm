/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and serves as the UI for Book metadata
* information like Table of Contents, Bookmarks
*
* Bookworm is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Bookworm is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Bookworm. If not, see http://www.gnu.org/licenses/.
*/
using Gtk;
using Gee;
public class BookwormApp.Info:Gtk.Window {
  public static Box info_box;
  public static Gtk.Stack stack;
  public static Box content_box;
  public static ScrolledWindow content_scroll;
  public static Box bookmarks_box;
  public static ScrolledWindow bookmarks_scroll;
  public static Box searchresults_box;
  public static ScrolledWindow searchresults_scroll;

  public static Gtk.Box createBookInfo(){
    debug("Starting to create BookInfo window components...");
    info_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    info_box.set_border_width(BookwormApp.Constants.SPACING_WIDGETS);

    //define the stack for the tabbed view
    stack = new Gtk.Stack();
    stack.set_transition_type(StackTransitionType.SLIDE_LEFT_RIGHT);
    stack.set_transition_duration(1000);

    //define the switcher for switching between tabs
    StackSwitcher switcher = new StackSwitcher();
    switcher.set_halign(Align.CENTER);
    switcher.set_stack(stack);

    content_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    content_scroll = new ScrolledWindow (null, null);
    content_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    content_scroll.add (content_box);
    stack.add_titled(content_scroll, "content-list", BookwormApp.Constants.TEXT_FOR_INFO_TAB_CONTENTS);

    bookmarks_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    bookmarks_scroll = new ScrolledWindow (null, null);
    bookmarks_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    bookmarks_scroll.add (bookmarks_box);
    stack.add_titled(bookmarks_scroll, "bookmark-list", BookwormApp.Constants.TEXT_FOR_INFO_TAB_BOOKMARKS);

    searchresults_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    searchresults_scroll = new ScrolledWindow (null, null);
    searchresults_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    searchresults_scroll.add (searchresults_box);
    stack.add_titled(searchresults_scroll, "searchresults-list", BookwormApp.Constants.TEXT_FOR_INFO_TAB_SEARCHRESULTS);

    info_box.pack_start(switcher, false, true, 0);
    info_box.pack_start(stack, true, true, 0);


    //Check every time a tab is clicked and perform necessary actions
    stack.notify["visible-child"].connect ((sender, property) => {
      if("bookmark-list"==stack.get_visible_child_name()){
        populateBookmarks();
      }
    });

    return info_box;
    debug("Sucessfully created BookInfo window components...");
  }

  public static void populateBookmarks(){
    //get the book being currently read
		BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
    Box bookmarks_box = new Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    Gtk.Label bookmarksLabel = new Label(BookwormApp.Constants.TEXT_FOR_BOOKMARKS_FOUND);
    bookmarks_box.pack_start(bookmarksLabel,false,false,0);
    if(aBook.getBookmark().index_of("**") != -1){
      string[] bookmarkList = aBook.getBookmark().split_set("**", -1);
      int bookmarkNumber = 1;
      foreach (string bookmarkedPage in bookmarkList) {
        if(bookmarkedPage != null && bookmarkedPage.length > 0){
          LinkButton bookmarkLinkButton = new LinkButton.with_label (bookmarkedPage, BookwormApp.Constants.TEXT_FOR_BOOKMARKS.replace("NNN", bookmarkNumber.to_string()).replace("PPP", bookmarkedPage));
          bookmarkNumber++;
          bookmarkLinkButton.halign = Align.START;
          bookmarks_box.pack_start(bookmarkLinkButton,false,false,0);
          bookmarkLinkButton.activate_link.connect (() => {
            aBook.setBookPageNumber(int.parse(bookmarkLinkButton.get_uri ().strip()));
            //update book details to libraryView Map
            BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
            aBook = BookwormApp.Bookworm.renderPage(aBook, "");
            //Set the mode back to Reading mode
            BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
            BookwormApp.Bookworm.getAppInstance().toggleUIState();
            return true;
          });
        }
      }
    }else{
      bookmarksLabel.set_text(BookwormApp.Constants.TEXT_FOR_BOOKMARKS_NOT_FOUND.replace("BBB", aBook.getBookTitle()));
    }
    //Remove the existing search results Gtk.Box and add the current one
    bookmarks_scroll.get_child().destroy();
    bookmarks_scroll.add (bookmarks_box);
    info_box.show_all();
  }

  public static BookwormApp.Book populateSearchResults(owned BookwormApp.Book aBook){
    Box searchresults_box = new Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    Gtk.Label searchLabel = new Label("");
    searchresults_box.pack_start(searchLabel,false,false,0);

    HashMap<string,string> searchResultsMap = BookwormApp.contentHandler.searchBookContents(aBook, BookwormApp.AppHeaderBar.headerSearchBar.get_text());
    if(searchResultsMap.size > 0){
      string searchResultsLabeltext = BookwormApp.Constants.TEXT_FOR_SEARCH_RESULTS_FOUND;
      searchResultsLabeltext = searchResultsLabeltext.replace("$$$", BookwormApp.AppHeaderBar.headerSearchBar.get_text());
      searchResultsLabeltext = searchResultsLabeltext.replace("&&&", aBook.getBookTitle());
      searchLabel.set_text(searchResultsLabeltext);
    }else{
      string searchResultsLabeltext = BookwormApp.Constants.TEXT_FOR_SEARCH_RESULTS_NOT_FOUND;
      searchResultsLabeltext = searchResultsLabeltext.replace("$$$", BookwormApp.AppHeaderBar.headerSearchBar.get_text());
      searchResultsLabeltext = searchResultsLabeltext.replace("&&&", aBook.getBookTitle());
      searchLabel.set_text(searchResultsLabeltext);
    }
    foreach (var entry in searchResultsMap.entries) {
      LinkButton searchResultLinkButton = new LinkButton.with_label (entry.key, entry.value);
      searchResultLinkButton.halign = Align.START;
      searchresults_box.pack_start(searchResultLinkButton,false,false,0);
      searchResultLinkButton.activate_link.connect (() => {
        aBook.setBookPageNumber(aBook.getBookContentList().index_of(searchResultLinkButton.get_uri ().strip()));
        //update book details to libraryView Map
        BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
        aBook = BookwormApp.Bookworm.renderPage(aBook, "");
        //Set the mode back to Reading mode
        BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
        BookwormApp.Bookworm.getAppInstance().toggleUIState();
        return true;
      });
    }

    //Remove the existing search results Gtk.Box and add the current one
    searchresults_scroll.get_child().destroy();
    searchresults_scroll.add (searchresults_box);

    return aBook;
  }

  public static BookwormApp.Book createTableOfContents(owned BookwormApp.Book aBook){
    Box content_box = new Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    //Use Table Of Contents if present
    if(aBook.getTOC().size > 0){
      ArrayList<HashMap<string,string>> tocList = aBook.getTOC();
      foreach(HashMap<string,string> tocListItemMap in tocList){
        foreach (var entry in tocListItemMap.entries) {
          LinkButton contentLinkButton = new LinkButton.with_label (entry.key, entry.value);
          contentLinkButton.halign = Align.START;
          content_box.pack_start(contentLinkButton,false,false,0);
          contentLinkButton.activate_link.connect (() => {
            aBook.setBookPageNumber(aBook.getBookContentList().index_of(contentLinkButton.get_uri ().strip()));
            //update book details to libraryView Map
            BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
            aBook = BookwormApp.Bookworm.renderPage(aBook, "");
            //Set the mode back to Reading mode
            BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
            BookwormApp.Bookworm.getAppInstance().toggleUIState();
            return true;
          });
        }
      }
    }else{
      //If Table Of Contents is not found, set the spine data into the Contents tab
      int contentNumber = 1;
      foreach(string contentPath in aBook.getBookContentList()){
        LinkButton contentLinkButton = new LinkButton.with_label (contentPath, BookwormApp.Constants.TEXT_FOR_INFO_TAB_CONTENT_PREFIX+contentNumber.to_string());
        contentLinkButton.halign = Align.START;
        content_box.pack_start(contentLinkButton,false,false,0);
        contentNumber++;
        contentLinkButton.activate_link.connect (() => {
          aBook.setBookPageNumber(aBook.getBookContentList().index_of(contentLinkButton.get_uri ()));
          //update book details to libraryView Map
          BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
          aBook = BookwormApp.Bookworm.renderPage(aBook, "");
          //Set the mode back to Reading mode
          BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
          BookwormApp.Bookworm.getAppInstance().toggleUIState();
          return true;
        });
      }
    }
    //Remove the existing content list Gtk.Box and add the current one
    content_scroll.get_child().destroy();
    content_scroll.add (content_box);

    return aBook;
  }
}
