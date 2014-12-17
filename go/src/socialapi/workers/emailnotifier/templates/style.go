package templates

const Style = `
body {
    margin: 10px;
}

.main-table {
    font-size: 13px;
    font-family: 'Open Sans', sans-serif;
    height:100%;
    color: #666;
    width:100%;
}

a {
    text-decoration:none;
    color:#1AAF5D;
}

/*
 *  Header
 */
.header {

}

.header-logo {
    width: 58px;
    text-align: right;
    border-right: 1px solid #ccc;
    margin-left: 12px;
    vertical-align: top;
}

.header .intro {
    padding: 6px 0 0 10px;
    padding-bottom:20px;
    margin-top: 0;
}
.header .intro h2 {
    margin-top: 0;
}

.header .date {
    text-align:center;
    width:90px;
    vertical-align:top;
}

.header p {
    font-size: 11px;
    color: #999;
    padding: 0 0 2px 0;
    margin-top: 4px;
}


/*
 *  Koding logo
 *  green with white bars
 */
.logo {
    margin-left: 12px;
    width: 40px;
    text-align: right;
    height: 40px;
    border:none;
    font-size: 0px;
    background-color: #1AAF5D;
    padding:9px;
}

.logo .bar-0 td {
    max-height: 1px;
    height:1px;
    background-color:white;
}

.logo .bar-1 td:first-child {
    max-height:1px;
    height:1px;
    background-color:white;
    width: 75%;
}
.logo .bar-1 td:last-child {
    max-height:1px;
    height:1px;
    background-color:#1AAF5D;
    width: 25%;
}

.logo .bar-2 td {
    max-height:1px;
    height:1px;
    background-color:white;
}

/*
 *  Content
 *  content.tmpl
 */
.content {
    vertical-align: top;
    background-color: white;
    color: #282623;
}

.content .time {
    width: 40px;
    text-align:right;
    border-right: 1px solid #CCC;
    color: #999;
    font-size:11px;
    line-height: 28px;
    padding-right:10px;
}

.content .inner {
    padding-left: 10px;
    color: #666;
}

.content .inner .action {
    line-height: 20px;
    padding-left:28px;
    padding-top:4px;
}

.content .time a {
    text-decoration:none;
    color:#999;
    pointer-event:none
}

/*
 *  Gravatar
 *  gravatar.tmpl
 */
.gravatar {
    border:none;
    margin-right:8px;
    float:left;
    margin-top:3px;
}

/*
 *  Footer
 */
.footer-before {
    height: 90%;
}
.footer-before td:first-child {
    width: 15px;
    border-right: 1px solid #CCC;
}
.footer-before td:last-child {
    height:40px;
    padding-left: 10px;
}

.footer {
    font-size:11px;
    height: 30px;
    color: #999;
}
.footer td:first-child {
    border-right: 1px solid #CCC;
    text-align:right;
    padding-right:10px;
}
.footer td:last-child {
    padding-left: 10px;
}

/*
 *  Preview
 *  preview.tmpl
 */
.preview {
    padding:10px;
    margin-left:28px;
    color:#777;
    margin-bottom:6px;
    margin-top: 4px;
    font-size:12px;
    background-color:#F8F8F8;
    border-radius:4px;
}
`
