/*
 * Collie - An asynchronous event-driven network framework using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the Apache-2.0 License.
 *
 */
module collie.socket.acceptor;

import core.memory;
import core.sys.posix.sys.socket;

import std.socket;
import std.functional;

import collie.socket.common;
import collie.socket.eventloop;
import collie.socket.transport;
import collie.utils.queue;
import collie.socket.tcpsocket;

alias AcceptCallBack = void delegate(Socket sock);

final class Acceptor : AsyncTransport, EventCallInterface
{
    this(EventLoop loop, bool isIpV6 = false)
    {
        if (isIpV6)
            _socket = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
        else
            _socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
        _socket.blocking = false;
        super(loop,TransportType.ACCEPT);
    }

	@property reusePort(bool use)
	{
		_socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, use);
		version (Posix)
			_socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption) SO_REUSEPORT,use);
	}

    void bind(Address addr) @trusted
    {
        _socket.bind(forward!addr);
    }

    void listen(int backlog) @trusted
    {
        _socket.listen(forward!backlog);
    }

    override @property int fd()
    {
        return cast(int) _socket.handle();
    }

    override bool start()
    {
        if (_event != null || !_socket.isAlive() || !_callBack)
            return false;
        _event = AsyncEvent.create(AsynType.ACCEPT, this, _socket.handle, true, false,
            false);
        _loop.addEvent(_event);
        return true;
    }

    override void close()
    {
        if (isAlive)
        {
          onClose();
        }
        else if (_socket.isAlive())
        {
            _socket.close();
        }
    }

    override @property bool isAlive() @trusted nothrow
    {
        try
        {
            return (_event != null) && _socket.isAlive();
        }
        catch
        {
            return false;
        }
    }

    mixin TransportSocketOption;

    void setCallBack(AcceptCallBack cback)
    {
        _callBack = cback;
    }

protected:
    override void onRead() nothrow
    {
        while (true)
        {
            socket_t fd = cast(socket_t)(.accept(_socket.handle, null, null));
            if (fd == socket_t.init)
                return;
            try
            {
                Socket sock = new Socket(fd, _socket.addressFamily);
                _callBack(sock);
            }
            catch (Exception e)
            {
                try
                {
                    error("\n\n----accept Exception! erro : ", e.msg, "\n\n");
                }
                catch
                {
                }
            }
        }
    }

    override void onWrite() nothrow
    {
    }

    override void onClose() nothrow
    {
        if (!isAlive)
            return;
        eventLoop.delEvent(_event);
        delete _event;
        _event = null;
        _socket.close();
    }

private:
    Socket _socket;
    AsyncEvent* _event = null;

    AcceptCallBack _callBack;
}

unittest
{
    /*
    import std.datetime;
    import std.stdio;
    import std.functional;

    import collie.socket;

    EventLoop loop = new EventLoop();

    

    class TCP
    {
        static int[TCP] tcpList;
        this(EventLoop loop, Socket soc)
        {
            _socket = new TCPSocket(loop, soc);
            _socket.setReadCallBack(&readed);
            _socket.setCloseCallBack(&closed);
            _socket.start();
        }

        alias socket this;
        @property socket()
        {
            return _socket;
        }

    protected:
        void readed(ubyte[] buf)
        {
            writeln("read data :  ", cast(string)(buf));
            socket.write(buf.dup, &writed);
        }

        void writed(ubyte[] data, uint size)
        {
            writeln("write data Size :  ", size, "\t data size : ", data.length);
            ++_size;
            if (_size == 5)
                socket.write(data, &writeClose);
            else
            {
                socket.write(data, &writed);
            }

        }

        void writeClose(ubyte[] data, uint size)
        {
            writeln("write data Size :  ", size, "\t data size : ", data.length);
            socket.close();
            loop.stop();
            //	throw new Exception("hahahahhaah ");
        }

        void closed()
        {
            tcpList.remove(this);
            writeln("Socket Closed .");
        }

    private:
        TCPSocket _socket;
        int _size = 0;
    }
      
    void newConnect(Socket soc)
    {
        auto tcp = new TCP(loop, soc);
        TCP.tcpList[tcp] = 0;
    }
    
    

    Acceptor accept = new Acceptor(loop);

    accept.setCallBack(toDelegate(&newConnect));

    accept.reusePort(true);
    accept.bind(new InternetAddress("0.0.0.0", 6553));

    accept.listen(64);

    accept.start();

    loop.run(5000);
*/
}
