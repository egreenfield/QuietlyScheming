////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2003-2006 Adobe Macromedia Software LLC and its licensors.
//  All Rights Reserved. The following is Source Code and is subject to all
//  restrictions on such code as contained in the End User License Agreement
//  accompanying this product.
//
////////////////////////////////////////////////////////////////////////////////

package mx.utils
{

[ExcludeClass]

public interface IXMLNotifiable
{
    function xmlNotification(currentTarget:Object,
                             type:String,
                             target:Object,
                             value:Object,
                             detail:Object):void;
}

}