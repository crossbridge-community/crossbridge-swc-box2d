/*
 * =BEGIN MIT LICENSE
 * 
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 The CrossBridge Team
 * https://github.com/crossbridge-community
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 * =END MIT LICENSE
 *
 */
package {
import crossbridge.Box2D.CModule;
import crossbridge.Box2D.vfs.ISpecialFile;

import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.text.TextField;

/**
 * Box2D Simple Demo for CrossBridge SDK
 */
[SWF(width="800", height="600", backgroundColor="#999999", frameRate="60")]
public class Boxes extends Sprite implements ISpecialFile {
    private var enableConsole:Boolean = true;
    private var _tf:TextField;
    private var inputContainer:DisplayObjectContainer;

    private var gravity:b2Vec2;
    private var world:b2World;
    private var groundBodyDef:b2BodyDef;
    private var groundBodyDefPos:b2Vec2;
    private var groundBody:b2Body;
    private var groundBox:b2PolygonShape;
    private var boxes:Vector.<Box2DSprite> = new Vector.<Box2DSprite>();

    private static const timeStep:Number = 1.0 / 60.0;
    private static const velocityIterations:int = 12;
    private static const positionIterations:int = 4;

    public function Boxes(container:DisplayObjectContainer = null) {
        CModule.rootSprite = container ? container.root : this;
        if (container) {
            container.addChild(this);
            onAdded(null);
        } else {
            addEventListener(Event.ADDED_TO_STAGE, onAdded);
        }
    }

    /**
     * @private
     */
    private function onAdded(event:Event):void {
        inputContainer = new Sprite();
        addChild(inputContainer);

        stage.frameRate = 60;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        if (enableConsole) {
            _tf = new TextField;
            _tf.multiline = true;
            _tf.width = stage.stageWidth;
            _tf.height = stage.stageHeight;
            inputContainer.addChild(_tf);
        }

        CModule.startAsync(this);

        // Define the gravity vector.
        gravity = b2Vec2.create();
        gravity.Set(0.0, -10.0);

        // Construct a world object, which will hold and simulate the rigid bodies.
        world = b2World.create(gravity.swigCPtr);

        // Define the ground body.
        groundBodyDef = b2BodyDef.create();
        groundBodyDefPos = b2Vec2.create();
        groundBodyDefPos.Set(0.0, -5.0);
        groundBodyDef.position = groundBodyDefPos.swigCPtr;

        // Call the body factory which allocates memory for the ground body
        // from a pool and creates the ground box shape (also from a pool).
        // The body is also added to the world.
        groundBody = new b2Body();
        groundBody.swigCPtr = world.CreateBody(groundBodyDef.swigCPtr);

        // Define the ground box shape.
        groundBox = b2PolygonShape.create();

        // The extents are the half-widths of the box.
        groundBox.SetAsBox(2000.0, 5.0);

        // Add the ground fixture to the ground body.
        groundBody.CreateFixture2(groundBox.swigCPtr, 0.0);

        const n:int = 500;
        for (var i:int = 0; i < n; i++) {
            var bs:Box2DSprite = new Box2DSprite(300 + random() * 200, 10 + random() * 3000, 10 + random() * 50, 2 + random() * 5, world);
            boxes.push(bs);
            addChild(bs);
        }
        consoleWrite("Added " + n + " Boxes ...");

        addEventListener(Event.ENTER_FRAME, onFrameEnter, false, 0, true);
    }

    /**
     * @private
     */
    private function onFrameEnter(event:Event):void {
        //Calling serviceUIRequests from the main worker allows us to service any requests
        //from background workers that want to use flash APIs that need main
        //worker privileges.
        CModule.serviceUIRequests();
        world.Step(timeStep, velocityIterations, positionIterations);
        const n:uint = boxes.length;
        for (var i:int = 0; i < n; i++) {
            boxes[i].update();
        }
    }

    /**
     * The PlayerKernel implementation will use this function to handle
     * C IO write requests to the file "/dev/tty" (e.g. output from
     * printf will pass through this function).
     */
    public function write(fd:int, buf:int, nbyte:int, errnoPtr:int):int {
        var str:String = CModule.readString(buf, nbyte);
        consoleWrite(str);
        return nbyte;
    }

    /**
     * The PlayerKernel implementation will use this function to handle
     * C IO read requests to the file "/dev/tty" (e.g. reads from stdin
     * will expect this function to provide the data).
     */
    public function read(fd:int, buf:int, nbyte:int, errnoPtr:int):int {
        return 0;
    }

    /**
     * The PlayerKernel implementation will use this function to handle
     * C fcntl requests to the file "/dev/tty"
     * See the ISpecialFile documentation for more information about the
     * arguments and return value.
     */
    public function fcntl(fd:int, com:int, data:int, errnoPtr:int):int {
        return 0;
    }

    /**
     * The PlayerKernel implementation will use this function to handle
     * C ioctl requests to the file "/dev/tty"
     * See the ISpecialFile documentation for more information about the
     * arguments and return value.
     */
    public function ioctl(fd:int, com:int, data:int, errnoPtr:int):int {
        return 0;
    }

    /**
     * Helper function that traces to the flashlog text file and also
     * displays output in the on-screen textfield console.
     */
    private function consoleWrite(s:String):void {
        trace(s);
        if (enableConsole) {
            _tf.appendText(s);
            _tf.scrollV = _tf.maxScrollV;
        }
    }

    // ======================================================
    // The following code is from Grant Skinner's Rndm.as
    // ======================================================

    /**
     * Rndm by Grant Skinner. Jan 15, 2008
     * Visit www.gskinner.com/blog for documentation, updates and more free code.
     *
     * Incorporates implementation of the Park Miller (1988) "minimal standard" linear
     * congruential pseudo-random number generator by Michael Baczynski, www.polygonal.de.
     * (seed * 16807) % 2147483647
     *
     *
     *
     * Copyright (c) 2008 Grant Skinner
     *
     * Permission is hereby granted, free of charge, to any person
     * obtaining a copy of this software and associated documentation
     * files (the "Software"), to deal in the Software without
     * restriction, including without limitation the rights to use,
     * copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the
     * Software is furnished to do so, subject to the following
     * conditions:
     *
     * The above copyright notice and this permission notice shall be
     * included in all copies or substantial portions of the Software.
     *
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
     * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
     * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
     * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
     * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
     * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
     * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
     * OTHER DEALINGS IN THE SOFTWARE.
     */

    protected var _currentSeed:uint = 1234;

    /**
     * returns a number between 0-1 exclusive.
     */
    public function random():Number {
        return (_currentSeed = (_currentSeed * 16807) % 2147483647) / 0x7FFFFFFF + 0.000000000233;
    }
}
}
